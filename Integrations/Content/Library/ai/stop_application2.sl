namespace: ai

flow:
  name: stop_application2
  inputs:
    # --- WebLogic Server Inputs ---
    - weblogic_host:
        default: "weblogicserver2" # Default based on description
        required: true
        description: Hostname or IP address of the WebLogic Linux server.
    - weblogic_ssh_user:
        required: true
        description: SSH username for connecting to the WebLogic server.
    - weblogic_ssh_password:
        required: true
        sensitive: true
        description: SSH password for the weblogic_ssh_user.
    - weblogic_stop_command:
        default: "sudo systemctl stop weblogic.service" # Example command, adjust as needed
        required: true
        description: The command to execute on the WebLogic server to stop the service.

    # --- Oracle Server Inputs ---
    - oracle_host:
        default: "oracleserver2" # Default based on description
        required: true
        description: Hostname or IP address of the Oracle Linux server.
    - oracle_ssh_user:
        required: true
        description: SSH username for connecting to the Oracle server.
    - oracle_ssh_password:
        required: true
        sensitive: true
        description: SSH password for the oracle_ssh_user.
    - oracle_stop_command:
        default: "sudo systemctl stop oracle-db.service" # Example command, adjust as needed
        required: true
        description: The command to execute on the Oracle server to stop the database/listener.

    # --- Optional SSH Configuration ---
    - ssh_port:
        default: '22'
        required: false
    - ssh_timeout:
        default: '90000' # milliseconds
        required: false
    - ssh_private_key_file:
        required: false
        description: Path to the private key file for SSH authentication (alternative to password).
    - ssh_passphrase:
        required: false
        sensitive: true
        description: Passphrase for the private key file, if encrypted.

  workflow:
    # Step 1: Stop the WebLogic service
    - stop_weblogic_service:
        do:
          io.cloudslang.base.remote_command_execution.ssh_command:
            - host: ${weblogic_host}
            - port: ${ssh_port}
            - username: ${weblogic_ssh_user}
            - password:
                value: ${weblogic_ssh_password}
                sensitive: true
            - private_key_file: ${ssh_private_key_file}
            - passphrase:
                value: ${ssh_passphrase}
                sensitive: true
            - command: ${weblogic_stop_command}
            - timeout: ${ssh_timeout}
            - pty: 'true' # Often needed for sudo commands
        publish:
          - weblogic_stop_stdout: ${stdout}
          - weblogic_stop_stderr: ${stderr}
          - weblogic_stop_return_code: ${return_code}
        navigate:
          - SUCCESS: check_weblogic_stop_status # Proceed only if return_code is 0 (success)
          - FAILURE: on_failure                 # Go to failure path on connection or execution error

    # Step 2: Check if WebLogic stop was successful (based on return code)
    - check_weblogic_stop_status:
        do:
          io.cloudslang.base.utils.equals:
            - arg1: ${weblogic_stop_return_code}
            - arg2: '0'
        navigate:
          - SUCCESS: stop_oracle_service # WebLogic stop command ran successfully (returned 0)
          - FAILURE: on_failure          # WebLogic stop command failed (non-zero return code)

    # Step 3: Stop the Oracle service (only if WebLogic stop succeeded)
    - stop_oracle_service:
        do:
          io.cloudslang.base.remote_command_execution.ssh_command:
            - host: ${oracle_host}
            - port: ${ssh_port}
            - username: ${oracle_ssh_user}
            - password:
                value: ${oracle_ssh_password}
                sensitive: true
            - private_key_file: ${ssh_private_key_file} # Assuming same key for simplicity, adjust if needed
            - passphrase:
                value: ${ssh_passphrase}
                sensitive: true
            - command: ${oracle_stop_command}
            - timeout: ${ssh_timeout}
            - pty: 'true' # Often needed for sudo commands
        publish:
          - oracle_stop_stdout: ${stdout}
          - oracle_stop_stderr: ${stderr}
          - oracle_stop_return_code: ${return_code}
        navigate:
          - SUCCESS: check_oracle_stop_status # Check the Oracle stop command's return code
          - FAILURE: on_failure               # Go to failure path on connection or execution error

    # Step 4: Check if Oracle stop was successful (based on return code)
    - check_oracle_stop_status:
        do:
          io.cloudslang.base.utils.equals:
            - arg1: ${oracle_stop_return_code}
            - arg2: '0'
        navigate:
          - SUCCESS: SUCCESS # Both stops succeeded
          - FAILURE: on_failure # Oracle stop command failed

  outputs:
    - weblogic_stop_status: >
        ${'Success' if weblogic_stop_return_code == '0' else 'Failed (Return Code: ' + str(weblogic_stop_return_code) + ')'}
    - weblogic_stop_output: ${weblogic_stop_stdout}
    - weblogic_stop_error: ${weblogic_stop_stderr}
    - oracle_stop_status: >
        ${'Success' if defined('oracle_stop_return_code') and oracle_stop_return_code == '0' else ('Not Attempted' if not defined('oracle_stop_return_code') else 'Failed (Return Code: ' + str(oracle_stop_return_code) + ')')}
    - oracle_stop_output: ${oracle_stop_stdout if defined('oracle_stop_stdout') else 'N/A'}
    - oracle_stop_error: ${oracle_stop_stderr if defined('oracle_stop_stderr') else 'N/A'}

  results:
    - SUCCESS
    - FAILURE
