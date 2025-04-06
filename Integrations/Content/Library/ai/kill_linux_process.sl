namespace: ai
flow:
 name: kill_linux_process
 inputs:
  - target_host:
    description: The hostname or IP address of the target Linux system.
    required: true
  - target_username:
    description: The username to connect to the target system via SSH.
    required: true
  - target_password:
    description: The password for the target username. Use private_key_file for key-based auth.
    required: true
    sensitive: true
  - process_id:
    description: The Process ID (PID) of the Linux process to kill.
    required: true
  - ssh_port:
    description: The SSH port on the target system.
    default: 22
    required: false
  - force_kill:
    description: If true, uses 'kill -9' (SIGKILL). If false, uses 'kill' (SIGTERM).
    default: false
    required: false
  - ssh_timeout:
    description: SSH connection and command execution timeout in milliseconds.
    default: 90000 # 90 seconds
    required: false
 workflow:
  - run_kill_command:
    do:
     io.cloudslang.base.ssh.ssh_command:
      - host: '${target_host}'
      - port: '${ssh_port}'
      - username: '${target_username}'
      - password:
        value: '${target_password}'
        sensitive: true
      # For key-based authentication (more secure), comment out password and use:
      # - private_key_file: "/path/to/private/key"
      # - passphrase:
      #     value: "your_passphrase_if_any"
      #     sensitive: true
      - command:
        '${'kill ' + ('-9 ' if force_kill else '') + str(process_id)}'
      - timeout: '${ssh_timeout}'
      -pty: false # Usually not needed for simple kill command
    publish:
     - command_stdout: '${stdout}'
     - command_stderr: '${stderr}'
     - command_return_code: '${return_code}'
     - command_return_result: '${return_result}' # Often same as stdout for ssh_command
     - command_exception: '${exception}'
    navigate:
     - SUCCESS: CHECK_RETURN_CODE
     - FAILURE: ON_FAILURE # Handle SSH connection errors etc.

  - CHECK_RETURN_CODE:
    do:
     io.cloudslang.base.utils.equals:
      - first: '${command_return_code}'
      - second: 0
    navigate:
     - SUCCESS: SUCCESS # Return code 0 means command likely succeeded
     - FAILURE: FAILURE # Non-zero return code indicates an issue (e.g., process not found)

 outputs:
  - stdout:
    description: Standard output from the kill command execution.
    value: '${command_stdout}'
  - stderr:
    description: Standard error from the kill command execution.
    value: '${command_stderr}'
  - return_code:
    description: The return code from the remote kill command execution (0 usually means success).
    value: '${command_return_code}'
  - exception:
    description: Any exception captured during the SSH operation.
    value: '${command_exception}'

 results:
  - SUCCESS
  - FAILURE
  - ON_FAILURE # Specific result for SSH-level failures vs command failures
