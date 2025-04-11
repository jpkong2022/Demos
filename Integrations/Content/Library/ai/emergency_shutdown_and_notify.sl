namespace: ai
flow:
  name: emergency_shutdown_and_notify
  inputs:
    # Email Inputs
    - mail_host:
        required: true
        description: SMTP server hostname or IP address.
    - mail_port:
        default: '25'
        description: SMTP server port.
    - mail_sender:
        required: true
        description: Email address of the sender.
    - mail_recipients:
        required: true
        description: Comma-separated list of recipient email addresses.
    - mail_subject:
        default: 'EMERGENCY ALERT: System Shutdown Initiated'
    - mail_body:
        default: 'An emergency situation has been declared. Key systems including Finance Application, WebLogic, and Oracle DB are being shut down immediately. A change request will be created in SMAX to track this event.'
    - mail_username:
        required: false
        description: Username for SMTP authentication (if required).
    - mail_password:
        required: false
        sensitive: true
        description: Password for SMTP authentication (if required).

    # Web Server Inputs (Finance App)
    - web_server_host:
        required: true
        description: Hostname or IP address of the web server.
    - web_server_user:
        required: true
        description: Username for SSH connection to the web server.
    - web_server_password:
        required: true
        sensitive: true
        description: Password for SSH connection to the web server.
    - finance_app_stop_command:
        required: true
        description: The exact command to stop the finance application (e.g., 'sudo systemctl stop finance-app').

    # Application Server Inputs (WebLogic)
    - app_server_host:
        required: true
        description: Hostname or IP address of the application server.
    - app_server_user:
        required: true
        description: Username for SSH connection to the application server.
    - app_server_password:
        required: true
        sensitive: true
        description: Password for SSH connection to the application server.
    - weblogic_stop_command:
        required: true
        description: The exact command to stop WebLogic (e.g., '/opt/weblogic/bin/stopWebLogic.sh').

    # Database Server Inputs (Oracle)
    - db_server_host:
        required: true
        description: Hostname or IP address of the database server.
    - db_server_user:
        required: true
        description: Username for SSH connection to the database server (e.g., 'oracle').
    - db_server_password:
        required: true
        sensitive: true
        description: Password for SSH connection to the database server.
    - oracle_stop_command:
        required: true
        description: The exact command sequence to stop Oracle DB (e.g., 'sqlplus / as sysdba <<EOF\nshutdown immediate;\nexit;\nEOF').

    # SMAX Inputs
    - smax_url:
        required: true
        description: Base URL of the SMAX instance (e.g., https://smax.example.com).
    - smax_tenant_id:
        required: true
        description: The tenant ID for SMAX.
    - smax_token:
        required: true
        sensitive: true
        description: An authentication token (e.g., SSO token) for SMAX API access.
    - change_title:
        default: 'Emergency Shutdown due to Unforeseen Event'
    - change_description:
        default: 'Executed emergency shutdown procedure: Sent user notifications, stopped Finance App, WebLogic, and Oracle DB.'
    - change_urgency:
        default: 'Critical' # Adjust based on SMAX valid values (e.g., ID or name)
    - change_category:
        required: false # Optional: Provide SMAX category if needed
        description: SMAX Category for the change request.
    - change_assignment_group:
        required: false # Optional: Assign to a specific group
        description: SMAX Assignment Group for the change request.

    # Optional Common Inputs
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true
    - trust_all_roots:
        default: 'false'
        required: false
    - x509_hostname_verifier:
        default: strict
        required: false

  workflow:
    - send_emergency_email:
        do:
          io.cloudslang.base.mail.send_mail:
            - hostname: ${mail_host}
            - port: ${mail_port}
            - html_email: 'false' # Assuming plain text
            - from: ${mail_sender}
            - to: ${mail_recipients}
            - subject: ${mail_subject}
            - body: ${mail_body}
            - username: ${mail_username}
            - password:
                value: ${mail_password}
                sensitive: true
        publish:
          - email_status: '${return_result}' # Capture result for potential logging/output
        navigate:
          - SUCCESS: stop_finance_app
          - FAILURE: on_failure # Decide if failure here stops everything or just logs

    - stop_finance_app:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${web_server_host}
            - username: ${web_server_user}
            - password:
                value: ${web_server_password}
                sensitive: true
            - command: ${finance_app_stop_command}
            - pty: 'true' # Often needed for sudo or interactive-like commands
        publish:
          - finance_stop_result: '${return_result}'
          - finance_stop_output: '${std_out}'
        navigate:
          - SUCCESS: stop_weblogic
          - FAILURE: on_failure # Continue or halt on failure? For emergency, might continue.

    - stop_weblogic:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${app_server_host}
            - username: ${app_server_user}
            - password:
                value: ${app_server_password}
                sensitive: true
            - command: ${weblogic_stop_command}
            - pty: 'true'
        publish:
          - weblogic_stop_result: '${return_result}'
          - weblogic_stop_output: '${std_out}'
        navigate:
          - SUCCESS: stop_oracle_db
          - FAILURE: on_failure # Continue or halt?

    - stop_oracle_db:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${db_server_host}
            - username: ${db_server_user}
            - password:
                value: ${db_server_password}
                sensitive: true
            - command: ${oracle_stop_command}
            - pty: 'true'
        publish:
          - oracle_stop_result: '${return_result}'
          - oracle_stop_output: '${std_out}'
        navigate:
          - SUCCESS: prepare_smax_change_body
          - FAILURE: on_failure # Continue or halt?

    - prepare_smax_change_body:
        do:
          # Simple step to construct the JSON body string, handling optional fields
          # (Could use a more complex script/operation for advanced JSON building if needed)
          io.cloudslang.base.utils.do_nothing: # Placeholder op, logic is in publish
        publish:
          - smax_change_json_body: |
              ${'{' +
                '"entity_type":"Change",' +
                '"properties":{' +
                '"DisplayLabel":"' + change_title + '",' +
                '"Description":"' + change_description + '",' +
                '"Urgency":"' + change_urgency + '"' +
                (get('change_category') != null ? ',"Category":"' + change_category + '"' : '') +
                (get('change_assignment_group') != null ? ',"AssignedGroup":"' + change_assignment_group + '"' : '') + # Note: Property name might be different (e.g., AssignedGroup, AssignmentGroup)
                '}' +
              '}'}
        navigate:
          - SUCCESS: create_smax_change
          - FAILURE: on_failure

    - create_smax_change:
        do:
          # Using the generic create_entity as shown in the SMAX incident example
          # Assuming similar structure for changes. Verify API docs for exact requirements.
          io.cloudslang.opentext.service_management_automation_x.commons.create_entity:
            - saw_url: ${smax_url}
            - sso_token: ${smax_token}
            - tenant_id: ${smax_tenant_id}
            - json_body: ${smax_change_json_body}
            - proxy_host: ${proxy_host}
            - proxy_port: ${proxy_port}
            - proxy_username: ${proxy_username}
            - proxy_password:
                value: ${proxy_password}
                sensitive: true
            - trust_all_roots: ${trust_all_roots}
            - x509_hostname_verifier: ${x509_hostname_verifier}
            # Add trust_keystore/trust_password if needed
        publish:
          - smax_change_id: '${created_id}'
          - smax_change_entity_json: '${entity_json}'
          - smax_change_error_json: '${error_json}'
          - smax_change_return_result: '${return_result}'
          - smax_change_op_status: '${op_status}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - email_status: '${email_status}'
    - finance_stop_result: '${finance_stop_result}'
    - weblogic_stop_result: '${weblogic_stop_result}'
    - oracle_stop_result: '${oracle_stop_result}'
    - smax_change_id: '${smax_change_id}'
    - smax_change_op_status: '${smax_change_op_status}'
    - smax_change_error_json: '${smax_change_error_json}'

  results:
    - SUCCESS
    - FAILURE
