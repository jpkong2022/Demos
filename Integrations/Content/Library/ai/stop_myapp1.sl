namespace: ai
flow:
  name: stop_myapp1
  inputs:
    # --- WebLogic Server Details (apacheserver1) ---
    - wls_admin_host:
        default: "apacheserver1" # Use the actual hostname or IP
        required: true
    - wls_admin_port:
        default: "7001" # Default WebLogic admin port
        required: true
    - wls_username:
        required: true
    - wls_password:
        required: true
        sensitive: true
    - wlst_path: # Path to wlst.sh/wlst.cmd on the target server
        default: "/path/to/oracle_common/common/bin/wlst.sh" # Adjust for your environment
        required: true
    - app_name:
        default: "myapp1"
        required: true

    # --- SSH Connection Details for WebLogic Server ---
    - ssh_username: # User to SSH into the WebLogic server host
        required: true
    - ssh_password: # Password for SSH user
        required: true
        sensitive: true
    - ssh_port:
        default: "22"
        required: false
    - ssh_timeout:
        default: "90000" # milliseconds
        required: false

    # --- Optional Proxy Details (if needed for SSH/WLST connection) ---
    # Add proxy inputs (proxy_host, proxy_port, etc.) if required by ssh_command or WLST itself

  workflow:
    # Step 1: Construct the WLST command to stop the application
    - construct_wlst_command:
        do:
          # This step isn't strictly necessary as we can build the command
          # directly in the next step, but it can improve readability.
          # Using io.cloudslang.base.utils.string_formatter might be cleaner
          # but simple concatenation works too.
          # Note: Adjust WLST commands based on your specific WebLogic version and security setup (e.g., t3s for SSL)
          io.cloudslang.base.utils.do_nothing: # Placeholder, real logic is in publish
        publish:
          # Carefully construct the command string. Quotes are important.
          # This assumes wlst.sh can be run directly.
          # It connects, stops the application, disconnects, and exits.
          - wlst_command: >
              ${wlst_path} -skipWLSModuleScanning <<-EOF
              connect('${wls_username}', '${wls_password}', 't3://${wls_admin_host}:${wls_admin_port}')
              stopApplication('${app_name}')
              disconnect()
              exit()
              EOF
        navigate:
          - SUCCESS: execute_stop_command
          - FAILURE: on_failure # Should not fail unless there's an internal error

    # Step 2: Execute the WLST command remotely via SSH on the WebLogic server host
    - execute_stop_command:
        do:
          # Using the standard SSH command operation
          io.cloudslang.base.remote_command_execution.ssh_command:
            - host: ${wls_admin_host} # SSH target is the WebLogic server host
            - port: ${ssh_port}
            - username: ${ssh_username}
            - password:
                value: ${ssh_password}
                sensitive: true
            - command: ${wlst_command} # The command constructed in the previous step
            - timeout: ${ssh_timeout}
            # Add other SSH parameters if needed (pty, private_key_file, etc.)
        publish:
          - ssh_return_code: ${return_code}
          - ssh_return_result: ${return_result}
          - ssh_exception: ${exception}
        navigate:
          # Check the return code from the SSH command execution itself
          - SUCCESS: check_wlst_result # SSH command ran, now check WLST output/code
          - FAILURE: on_failure     # SSH command failed to execute (e.g., connection error)

    # Step 3: Check the result of the WLST script execution
    - check_wlst_result:
        do:
          # Simple check: Assume WLST script exits non-zero on error.
          # A more robust check might parse ssh_return_result for specific
          # success or error messages from WLST.
          io.cloudslang.base.comparisons.equals:
            - compare_value: ${ssh_return_code}
            - equal_to: "0"
        navigate:
          # If ssh_return_code is 0, assume WLST script succeeded
          - SUCCESS: SUCCESS
          # If ssh_return_code is non-zero, assume WLST script failed
          - FAILURE: on_failure

  outputs:
    - status: # Provide a simple status output
        value: ${ 'Application ' + app_name + ' stop command executed successfully.' if ssh_return_code == '0' else 'Failed to stop application ' + app_name + '.' }
    - wlst_output: ${ssh_return_result}
    - wlst_exit_code: ${ssh_return_code}
    - error_details: ${ssh_exception} # Captures SSH execution errors

  results:
    - SUCCESS # Reached if check_wlst_result comparison is true (exit code 0)
    - FAILURE # Reached if any step navigates to on_failure
