namespace: ai

flow:
  name: stop_myapp1
  description: Stops the myapp1 application by stopping its dependency Apache server service.

  inputs:
    # Inputs for connecting to the Apache Server (apacheserver1)
    - apache_host:
        description: Hostname or IP address of the Apache server (apacheserver1).
        required: true
    - apache_user:
        description: Username for SSH connection to the Apache server.
        required: true
    - apache_password:
        description: Password for the apache_user on the Apache server.
        required: true
        sensitive: true
    - apache_service_name:
        description: The name of the Apache service to stop (e.g., httpd, apache2).
        default: 'httpd' # Common default for RHEL/CentOS, adjust if needed (e.g., 'apache2' for Debian/Ubuntu)
        required: true
    - ssh_port:
        description: SSH port for the Apache server.
        default: '22'
        required: false
    - ssh_timeout:
        description: SSH connection timeout in milliseconds.
        default: '90000' # 90 seconds
        required: false
    # Optional: Inputs for connecting to the Oracle Server (oracleserver1) if needed for a coordinated stop
    # - oracle_host:
    # - oracle_user:
    # - oracle_password:
    # - oracle_service_name: # e.g., listener or specific instance SID

    # Optional Proxy Inputs (if connection needs to go through a proxy)
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

  workflow:
    # Step 1: Stop the Apache service on apacheserver1
    - stop_apache_service:
        do:
          # Using a common SSH command operation. Replace with the specific operation available in your OO environment if different.
          # Assumes io.cloudslang.base content pack is available.
          # Assumes the target OS uses systemd (systemctl). Adjust command if using init.d (service)
          io.cloudslang.base.remote_command_execution.ssh_command:
            - host: ${apache_host}
            - port: ${ssh_port}
            - username: ${apache_user}
            - password:
                value: ${apache_password}
                sensitive: true
            # Command to stop the service. Using sudo is common.
            # Ensure the apache_user has passwordless sudo rights for this command,
            # or use root user (less recommended), or handle sudo password prompt if the operation supports it.
            - command: "sudo systemctl stop ${apache_service_name}"
            - timeout: ${ssh_timeout}
            - proxy_host: ${proxy_host}
            - proxy_port: ${proxy_port}
            - proxy_username: ${proxy_username}
            - proxy_password:
                value: ${proxy_password}
                sensitive: true
            # Add other relevant ssh options if needed (e.g., private_key_file, known_hosts_policy)
        publish:
          - apache_stop_return_code: ${return_code}
          - apache_stop_output: ${return_result} # Standard output
          - apache_stop_error: ${error_message} # Standard error or exception message
        navigate:
          # Check the return code of the ssh_command operation itself AND the command executed
          - SUCCESS: check_apache_stop_result # ssh command executed successfully, now check the command's exit code
          - FAILURE: on_failure # ssh command failed to execute (e.g., connection error)

    # Step 2: Check the result of the stop command
    - check_apache_stop_result:
        do:
          # Simple check if return_code from the command execution is 0 (success)
          io.cloudslang.base.comparisons.equal:
            - value1: ${apache_stop_return_code}
            - value2: '0'
        navigate:
          # If apache_stop_return_code == 0
          - SUCCESS: SUCCESS # Apache service stop command executed successfully
          # If apache_stop_return_code != 0
          - FAILURE: on_failure # Apache service stop command failed

    # (Optional) Step 3: Stop Oracle Service on oracleserver1
    # If stopping the Oracle DB is also required as part of stopping myapp1, add steps here similar to stop_apache_service
    # - stop_oracle_service:
    #     do:
    #       # Use appropriate operation (e.g., ssh_command, sql_command)
    #     navigate:
    #       - SUCCESS: SUCCESS
    #       - FAILURE: on_failure

    # Define the failure path
    - on_failure:
        do:
          # Placeholder for any specific failure handling logic if needed
          # For now, just transitions to the FAILURE result
          io.cloudslang.base.utils.do_nothing: []
        navigate:
          - SUCCESS: FAILURE # Ensure it always goes to the FAILURE result

  outputs:
    - status_message:
        # Provide a status message based on success or intermediate outputs
        # This is a simplified example; more logic could be added
        value: >
          ${
            (result == 'SUCCESS')
            ? ('Successfully stopped Apache service ' + apache_service_name + ' on ' + apache_host)
            : ('Failed to stop Apache service. Error: ' + apache_stop_error + ' Output: ' + apache_stop_output)
          }
    - apache_stop_output: ${apache_stop_output}
    - apache_stop_error: ${apache_stop_error}
    - apache_stop_return_code: ${apache_stop_return_code}

  results:
    - SUCCESS: ${apache_stop_return_code == '0'} # Define success condition based on command execution
    - FAILURE
