namespace: ai

imports:
  ssh: io.cloudslang.base.ssh
  mail: io.cloudslang.base.mail

flow:
  name: shutdown_weblogic_oracle_with_notification

  inputs:
    # Email details
    - smtp_hostname: smtp.example.com
    - smtp_port: '25' # Use '465' or '587' for SSL/TLS typically
    - smtp_username:
        required: false
    - smtp_password:
        required: false
        sensitive: true
    - email_from: notifications@example.com
    - email_to: team@example.com # Comma-separated for multiple recipients
    - email_subject: "Planned Application and Database Shutdown"
    - email_body: "Please be advised that WebLogic and Oracle will be shut down shortly for maintenance."

    # WebLogic App Server details
    - app_server_host:
        required: true
        description: IP or hostname of the WebLogic server.
    - app_server_user:
        required: true
        description: SSH username for the WebLogic server.
    - app_server_password:
        required: true
        description: SSH password for the WebLogic server.
        sensitive: true
    - weblogic_stop_command:
        default: "/opt/weblogic/bin/stopWebLogic.sh" # Example path, adjust as needed
        description: The command to execute on the app server to stop WebLogic.

    # Oracle DB Server details
    - db_server_host:
        required: true
        description: IP or hostname of the Oracle DB server.
    - db_server_user:
        required: true
        description: SSH username for the Oracle DB server (e.g., oracle).
    - db_server_password:
        required: true
        description: SSH password for the Oracle DB server.
        sensitive: true
    - oracle_stop_command:
        default: "sudo /u01/app/oracle/product/19c/dbhome_1/bin/dbshut" # Example path/command, adjust as needed
        description: The command to execute on the DB server to stop Oracle. Use appropriate sudo/permissions if required.

  workflow:
    - send_notification:
        do:
          mail.send_mail:
            - hostname: ${smtp_hostname}
            - port: ${smtp_port}
            # Uncomment if authentication is needed
            # - username: ${smtp_username}
            # - password:
            #     value: ${smtp_password}
            #     sensitive: true
            - from: ${email_from}
            - to: ${email_to}
            - subject: ${email_subject}
            - body: ${email_body}
        publish:
          - mail_send_result: ${return_result}
          - mail_send_exception: ${exception}
        navigate:
          - SUCCESS: stop_weblogic
          - FAILURE: on_failure # Fail if email notification fails

    - stop_weblogic:
        do:
          ssh.ssh_command:
            - host: ${app_server_host}
            - username: ${app_server_user}
            - password:
                value: ${app_server_password}
                sensitive: true
            - command: ${weblogic_stop_command}
            - timeout: '120000' # 2 minutes timeout, adjust as needed
        publish:
          - weblogic_stop_result: ${return_result}
          - weblogic_stop_output: ${stdout}
          - weblogic_stop_error: ${stderr}
          - weblogic_stop_exception: ${exception}
        navigate:
          - SUCCESS: stop_oracle
          - FAILURE: on_failure

    - stop_oracle:
        do:
          ssh.ssh_command:
            - host: ${db_server_host}
            - username: ${db_server_user}
            - password:
                value: ${db_server_password}
                sensitive: true
            - command: ${oracle_stop_command}
            - pty: true # Often needed for sudo or interactive prompts
            - timeout: '180000' # 3 minutes timeout, adjust as needed
        publish:
          - oracle_stop_result: ${return_result}
          - oracle_stop_output: ${stdout}
          - oracle_stop_error: ${stderr}
          - oracle_stop_exception: ${exception}
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - shutdown_status: ${return_result} # Will be the result of the last step or FAILURE
    - weblogic_stop_output: ${weblogic_stop_output}
    - oracle_stop_output: ${oracle_stop_output}
    - error_message: >
        ${ 'Mail Exception: ' + mail_send_exception if mail_send_exception is not None else '' +
           'WebLogic Stop Exception: ' + weblogic_stop_exception if weblogic_stop_exception is not None else '' +
           'Oracle Stop Exception: ' + oracle_stop_exception if oracle_stop_exception is not None else '' +
           'WebLogic STDERR: ' + weblogic_stop_error if weblogic_stop_error is not None else '' +
           'Oracle STDERR: ' + oracle_stop_error if oracle_stop_error is not None else '' }

  results:
    - SUCCESS
    - FAILURE
