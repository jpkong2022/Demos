namespace: ai

imports:
  ssh: io.cloudslang.base.ssh
  mail: io.cloudslang.base.mail
  utils: io.cloudslang.base.utils

flow:
  name: coordinated_shutdown_weblogic_oracle

  inputs:
    # --- Email Inputs ---
    - mail_host: smtp.example.com             # Replace with your SMTP server
    - mail_port: '25'                         # Standard SMTP port, adjust if needed
    - mail_sender: orchestrator@example.com   # Replace with sender email
    - mail_recipients: user1@example.com,admin@example.com # Comma-separated list of recipients
    - mail_subject: "Planned Service Shutdown Notification"
    - mail_body: "Services including WebLogic and Oracle Database will be shut down shortly for maintenance."
    # Optional: email credentials if authentication is needed
    # - mail_username:
    # - mail_password:
    #     sensitive: true

    # --- Application Server Inputs ---
    - app_server_host: 192.168.1.100          # Replace with App Server IP/hostname
    - app_server_user: weblogic_admin        # Replace with user that can stop WebLogic
    - app_server_password:                     # Use password OR private_key_file
        sensitive: true
        required: false
    # - app_server_private_key_file: /path/to/app_server_key.pem # Alternative to password
    #     required: false
    - weblogic_stop_command: "/opt/weblogic/domains/mydomain/bin/stopWebLogic.sh" # Adjust path as needed

    # --- Database Server Inputs ---
    - db_server_host: 192.168.1.101           # Replace with DB Server IP/hostname
    - db_server_user: oracle                 # Replace with user that can stop Oracle
    - db_server_password:                      # Use password OR private_key_file
        sensitive: true
        required: false
    # - db_server_private_key_file: /path/to/db_server_key.pem # Alternative to password
    #     required: false
    - oracle_stop_command: "lsnrctl stop; echo 'shutdown immediate' | sqlplus / as sysdba" # Adjust command as needed (may require sudo/specific paths)

    # --- Timing Input ---
    - wait_duration_ms: '60000' # 1 minute in milliseconds

  workflow:
    - send_shutdown_email:
        do:
          mail.send_mail:
            - hostname: ${mail_host}
            - port: ${mail_port}
            - from: ${mail_sender}
            - to: ${mail_recipients}
            - subject: ${mail_subject}
            - body: ${mail_body}
            # Add username/password if needed for SMTP auth
            # - username: ${mail_username}
            # - password: ${mail_password}
            - htmlEmail: 'false' # Send as plain text
        navigate:
          - SUCCESS: wait_period
          - FAILURE: on_failure # Fail flow if email fails

    - wait_period:
        do:
          utils.sleep:
            - duration: ${wait_duration_ms}
        navigate:
          - SUCCESS: stop_weblogic
          # Sleep generally doesn't fail unless interrupted externally

    - stop_weblogic:
        do:
          ssh.ssh_command:
            - host: ${app_server_host}
            - username: ${app_server_user}
            - password: ${app_server_password}
            # - private_key_file: ${app_server_private_key_file} # Use instead of password if needed
            - command: ${weblogic_stop_command}
            - timeout: '120000' # 2 minute timeout for stop command
        publish:
          - weblogic_stop_result: '${return_result}'
          - weblogic_stop_exit_code: '${return_code}'
        navigate:
          - SUCCESS: stop_oracle # Continue even if stop command returns non-zero, assuming it might still succeed partially or eventually
          - FAILURE: on_failure # Handle SSH connection errors etc.

    - stop_oracle:
        do:
          ssh.ssh_command:
            - host: ${db_server_host}
            - username: ${db_server_user}
            - password: ${db_server_password}
            # - private_key_file: ${db_server_private_key_file} # Use instead of password if needed
            - command: ${oracle_stop_command}
            - timeout: '180000' # 3 minute timeout for stop command
        publish:
          - oracle_stop_result: '${return_result}'
          - oracle_stop_exit_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS # Final step succeeded
          - FAILURE: on_failure # Handle SSH connection errors etc.

  outputs:
    - weblogic_stop_result: ${weblogic_stop_result}
    - weblogic_stop_exit_code: ${weblogic_stop_exit_code}
    - oracle_stop_result: ${oracle_stop_result}
    - oracle_stop_exit_code: ${oracle_stop_exit_code}

  results:
    - SUCCESS
    - FAILURE
