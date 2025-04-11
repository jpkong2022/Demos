namespace: ai
flow:
  name: emergency_finance_shutdown_and_change
  inputs:
    # Email Inputs
    - email_to: # e.g., 'all-users@mycompany.com'
    - email_subject: 'Urgent: Planned System Maintenance'
    - email_body: 'Urgent maintenance is underway. Finance application access will be temporarily suspended.'
    - email_host: # e.g., 'smtp.mycompany.com'
    - email_port: '587' # Common port for TLS
    - email_username:
    - email_password:
        sensitive: true
    - email_sender: # e.g., 'it-alerts@mycompany.com'

    # Web Server Inputs
    - web_server_host:
    - web_server_username:
    - web_server_password:
        sensitive: true
    - finance_stop_command: 'sudo systemctl stop finance-app.service' # Example command

    # App Server Inputs
    - app_server_host:
    - app_server_username:
    - app_server_password:
        sensitive: true
    - weblogic_stop_command: '/opt/weblogic/bin/stopWebLogic.sh' # Example command

    # DB Server Inputs
    - db_server_host:
    - db_server_username:
    - db_server_password:
        sensitive: true
    - oracle_stop_command: '/opt/oracle/scripts/db_shutdown.sh' # Example command (could also use sqlplus commands directly)

    # SMAX Inputs
    - smax_url:
    - smax_sso_token:
    - smax_tenant_id:
    - change_title: 'Emergency Finance Application Shutdown'
    - change_description: 'Performed emergency shutdown of Finance App, WebLogic, and Oracle DB due to critical issue.'
    - change_reason: 'Emergency Maintenance'
    - change_justification: 'Required for system stability.'
    - change_category: # Optional SMAX change category ID/name
    - change_service: # Optional SMAX service ID/name
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
    - connect_timeout:
        default: '0'
        required: false

  workflow:
    - send_notification_email:
        do:
          io.cloudslang.base.mail.send_mail:
            - hostname: ${email_host}
            - port: ${email_port}
            - username: ${email_username}
            - password:
                value: ${email_password}
                sensitive: true
            - from: ${email_sender}
            - to: ${email_to}
            - subject: ${email_subject}
            - body: ${email_body}
            - html_email: 'false' # Assuming plain text email
            - timeout: '60000' # 60 second timeout
        navigate:
          - SUCCESS: stop_finance_app
          - FAILURE: on_failure

    - stop_finance_app:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${web_server_host}
            - username: ${web_server_username}
            - password:
                value: ${web_server_password}
                sensitive: true
            - command: ${finance_stop_command}
            - timeout: '120000' # 2 minute timeout
            - pty: 'true' # Often needed for sudo commands
        publish:
          - finance_stop_result: '${return_result}'
          - finance_stop_code: '${return_code}'
        navigate:
          - SUCCESS: stop_weblogic
          - FAILURE: on_failure # Consider if failure here should stop the whole flow or proceed

    - stop_weblogic:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${app_server_host}
            - username: ${app_server_username}
            - password:
                value: ${app_server_password}
                sensitive: true
            - command: ${weblogic_stop_command}
            - timeout: '300000' # 5 minute timeout
        publish:
          - weblogic_stop_result: '${return_result}'
          - weblogic_stop_code: '${return_code}'
        navigate:
          - SUCCESS: stop_oracle_db
          - FAILURE: on_failure # Consider behavior on failure

    - stop_oracle_db:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${db_server_host}
            - username: ${db_server_username}
            - password:
                value: ${db_server_password}
                sensitive: true
            - command: ${oracle_stop_command}
            - timeout: '600000' # 10 minute timeout
        publish:
          - oracle_stop_result: '${return_result}'
          - oracle_stop_code: '${return_code}'
        navigate:
          - SUCCESS: create_smax_change
          - FAILURE: on_failure # Consider behavior on failure

    - create_smax_change:
        # NOTE: Assuming an operation io.cloudslang.opentext.service_management_automation_x.changes.create_change exists
        #       similar to the create_incident example. If not, this step would need to be built
        #       using io.cloudslang.base.http.http_client operations.
        #       The json_body structure is also an assumption based on typical SMAX API patterns.
        do:
          io.cloudslang.opentext.service_management_automation_x.commons.create_entity: # Using generic create_entity
            - saw_url: ${smax_url}
            - sso_token: ${smax_sso_token}
            - tenant_id: ${smax_tenant_id}
            - json_body: >
                ${'{
                  "entity_type": "Change",
                  "properties": {
                      "DisplayLabel": "' + change_title + '",
                      "Description": "' + change_description + '",
                      "ReasonForChange": "' + change_reason + '",
                      "Justification": "' + change_justification + '"' +
                      (change_category != null ? ', "Category": "' + change_category + '"' : '') +
                      (change_service != null ? ', "BasedOnChangeModel": { "Service": "' + change_service + '" }' : '') +
                      # Add other relevant change properties here as needed
                  '}
                }'}
            - proxy_host: ${proxy_host}
            - proxy_port: ${proxy_port}
            - proxy_username: ${proxy_username}
            - proxy_password:
                value: ${proxy_password}
                sensitive: true
            - trust_all_roots: ${trust_all_roots}
            - x509_hostname_verifier: ${x509_hostname_verifier}
            - connect_timeout: ${connect_timeout}
        publish:
          - change_id: '${created_id}' # Assuming create_entity returns 'created_id'
          - change_entity_json: '${entity_json}'
          - change_error_json: '${error_json}'
          - change_return_result: '${return_result}'
          - change_op_status: '${op_status}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - change_id: '${change_id}'
    - change_op_status: '${change_op_status}'
    - finance_stop_code: '${finance_stop_code}'
    - weblogic_stop_code: '${weblogic_stop_code}'
    - oracle_stop_code: '${oracle_stop_code}'

  results:
    - SUCCESS
    - FAILURE
