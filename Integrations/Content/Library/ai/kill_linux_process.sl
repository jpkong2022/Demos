namespace: ai

operation:
  name: kill_linux_process

  inputs:
    - host:
        description: Hostname or IP address of the target Linux machine.
        required: true
    - port:
        description: The SSH port.
        default: 22
        required: false
    - username:
        description: The username for SSH connection.
        required: true
    - password:
        description: The password for SSH connection. Use private_key_file if preferred.
        required: false
        sensitive: true
    - private_key_file:
        description: Path to the private key file for SSH connection.
        required: false
    - process_identifier:
        description: The identifier of the process to kill (either PID or process name).
        required: true
    - identifier_type:
        description: "The type of the process identifier: 'pid' or 'name'."
        required: true
        default: 'pid'
    - force_kill:
        description: If true, use 'kill -9' or 'pkill -9' (SIGKILL). If false (default), use SIGTERM.
        required: false
        default: false
    - timeout:
        description: SSH command timeout in seconds.
        required: false
        default: 90 # Default timeout of 90 seconds

  tasks:
    - select_kill_command_type:
        decision:
          - use_pid: ${identifier_type == 'pid'}
          - use_name: ${identifier_type == 'name'}
          - invalid_type: # Default case if neither 'pid' nor 'name'
              # Navigate directly to a failure state if type is invalid
              do:
                # This is a placeholder action; navigation handles the result
                io.cloudslang.base.utils.do_nothing: []
              navigate:
                - SUCCESS: on_invalid_type

    - kill_by_pid:
        # This task runs if identifier_type is 'pid'
        do:
          io.cloudslang.base.remote_command.ssh_command:
            - host: ${host}
            - port: ${port}
            - username: ${username}
            - password:
                value: ${password}
                sensitive: true
            - private_key_file: ${private_key_file}
            - command: ${'kill ' + ('-9 ' if force_kill else '') + process_identifier}
            - timeout: ${timeout}
        publish:
          - pid_return_code: ${return_code}
          - pid_return_result: ${return_result}
          - pid_exception: ${exception}
        navigate:
          - SUCCESS: merge_results
          - FAILURE: merge_results # Also go to merge on failure to capture outputs

    - kill_by_name:
        # This task runs if identifier_type is 'name'
        do:
          io.cloudslang.base.remote_command.ssh_command:
            - host: ${host}
            - port: ${port}
            - username: ${username}
            - password:
                value: ${password}
                sensitive: true
            - private_key_file: ${private_key_file}
            # Use pkill for names - it's designed for killing by name
            - command: ${'pkill ' + ('-f ' if '/' in process_identifier else '') + ('-9 ' if force_kill else '') + process_identifier}
            # Added '-f' flag heuristically if identifier contains '/' assuming it might be a path part
            - timeout: ${timeout}
        publish:
          - name_return_code: ${return_code}
          - name_return_result: ${return_result}
          - name_exception: ${exception}
        navigate:
          - SUCCESS: merge_results
          - FAILURE: merge_results # Also go to merge on failure to capture outputs

    - merge_results:
        # Merges outputs from either kill_by_pid or kill_by_name path
        publish:
          # Use SystemProperties.get() to safely get potentially undefined variables
          - final_return_code: ${SystemProperties.get('pid_return_code', SystemProperties.get('name_return_code', '-1'))}
          - final_return_result: ${SystemProperties.get('pid_return_result', SystemProperties.get('name_return_result', ''))}
          - final_exception: ${SystemProperties.get('pid_exception', SystemProperties.get('name_exception', null))}
        navigate:
          # Determine SUCCESS/FAILURE based on the merged return code
          - SUCCESS: ${final_return_code == '0'}
          - FAILURE: FAILURE # Navigate to operation failure if code is non-zero or exception exists

    - on_invalid_type:
        # Task executed if identifier_type is invalid
        publish:
          - final_return_code: '-2' # Specific code for invalid input
          - final_return_result: "Error: Invalid identifier_type provided. Must be 'pid' or 'name'."
          - final_exception: "Invalid input: identifier_type was '${identifier_type}'"
        navigate:
          - SUCCESS: FAILURE # This path always results in operation failure

  outputs:
    # Expose the final merged results as operation outputs
    - return_code: ${final_return_code}
    - return_result: ${final_return_result}
    - exception: ${final_exception}

  results:
    # Define the final outcomes of the operation
    - SUCCESS: ${final_return_code == '0'}
    - FAILURE # Catches any non-zero return code or navigation to FAILURE
