namespace: ai

flow:
  name: shutdown_application2
  inputs:
    # --- WebLogic Server Credentials ---
    - weblogic_host:
        default: "10.10.1.2" # weblogicserver2 IP
        required: false
    - weblogic_user:
        required: true # e.g., 'weblogic' or an admin user
    - weblogic_password:
        required: true
        sensitive: true
    - weblogic_stop_command:
        default: "sudo systemctl stop weblogic_app2.service" # Example: Adjust command as needed (e.g., /path/to/domain/bin/stopWebLogic.sh)
        required: false

    # --- Oracle Server Credentials ---
    - oracle_host:
        default: "10.10.1.3" # oracleserver2 IP
        required: false
    - oracle_user:
        required: true # e.g., 'oracle' or an admin user
    - oracle_password:
        required: true
        sensitive: true
    - oracle_stop_command:
        # Example: Using sqlplus. Adjust user/method (e.g., srvctl) as needed.
        # Assumes oracle_user has sudo rights or direct access to stop the DB.
        default: "sudo su - oracle -c 'sqlplus / as sysdba <<EOF\nSHUTDOWN IMMEDIATE;\nEXIT;\nEOF'" # Example command
        required: false

    # --- Optional SSH Port and Timeout ---
    - ssh_port:
        default: 22
        required: false
    - ssh_timeout:
        default: 90000 # 90 seconds
        required: false

  workflow:
    # Step 1: Stop the WebLogic Server process
    - stop_weblogic:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${weblogic_host}
            - port: ${ssh_port}
            - username: ${weblogic_user}
            - password:
                value: ${weblogic_password}
                sensitive: true
            - command: ${weblogic_stop_command}
            - pty: true # Often helpful for sudo or service commands
            - timeout: ${ssh_timeout}
        publish:
          - weblogic_stop_result: '${return_result}'
          - weblogic_stop_code: '${return_code}'
        navigate:
          # Proceed to stop Oracle only if WebLogic stop succeeds (return_code 0)
          - SUCCESS: check_oracle_dependency # Or directly to stop_oracle if no check needed
          - FAILURE: on_failure

    # Step 2: Check if Oracle needs stopping (Optional - depends on exact dependencies)
    # For simplicity, we assume Oracle should always be stopped after WebLogic for app2 shutdown.
    - check_oracle_dependency:
        do:
          io.cloudslang.base.utils.do_nothing: # Placeholder step, directly navigate
        navigate:
          - SUCCESS: stop_oracle

    # Step 3: Stop the Oracle Database process
    - stop_oracle:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${oracle_host}
            - port: ${ssh_port}
            - username: ${oracle_user}
            - password:
                value: ${oracle_password}
                sensitive: true
            - command: ${oracle_stop_command}
            - pty: true # Often helpful for sudo/su commands
            - timeout: ${ssh_timeout}
        publish:
          - oracle_stop_result: '${return_result}'
          - oracle_stop_code: '${return_code}'
        navigate:
          # If Oracle stop succeeds, the overall flow succeeds
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - weblogic_stop_result: '${weblogic_stop_result}'
    - weblogic_stop_code: '${weblogic_stop_code}'
    - oracle_stop_result: '${oracle_stop_result}'
    - oracle_stop_code: '${oracle_stop_code}'

  results:
    - SUCCESS
    - FAILURE
