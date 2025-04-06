namespace: ai

flow:
 name: run_who_command
 description: Executes the 'who' command on a remote host via SSH.

 inputs:
  - host:
    required: true
    description: The target host FQDN or IP address.
  - username:
    required: true
    description: The username for SSH connection.
  - password:
    required: true
    sensitive: true
    description: The password for SSH connection.
  - port:
    default: "22"
    required: false
    description: The SSH port number.
  - timeout:
    default: "90000" # 90 seconds
    required: false
    description: SSH connection and command execution timeout in milliseconds.

 workflow:
  - run_ssh_command:
    do:
     # NOTE: Ensure 'io.cloudslang.base' content pack (or equivalent providing ssh_command) is deployed.
     # The exact path might vary slightly based on the content pack version.
     io.cloudslang.base.ssh.ssh_command:
      - host: ${host}
      - port: ${port}
      - username: ${username}
      - password:
        value: ${password}
        sensitive: true
      - command: "who"
      - timeout: ${timeout}
      - pty: "false" # Generally not needed for non-interactive commands like 'who'
    publish:
     - command_stdout: ${stdout}
     - command_stderr: ${stderr}
     - command_return_code: ${return_code}
     - command_return_result: ${return_result} # The raw result message from the SSH operation
    navigate:
     # Check if the SSH operation itself failed (e.g., connection refused)
     - FAILURE: ON_FAILURE
     # If SSH operation succeeded, check the command's return code
     - SUCCESS:
       # Check if return_code is '0' (success)
       - SUCCESS_CMD: "${command_return_code == '0'}"
       # Otherwise (return_code is not '0')
       - FAILURE_CMD

  - SUCCESS_CMD:
    # This step means the command executed successfully (return code 0)
    # We directly transition to the overall workflow SUCCESS result
    do:
     io.cloudslang.base.utils.do_nothing: []
    navigate:
     - SUCCESS: SUCCESS

  - FAILURE_CMD:
    # This step means the command executed but returned a non-zero exit code
    # We transition to the overall workflow FAILURE result
    do:
     io.cloudslang.base.utils.do_nothing: []
    navigate:
     - SUCCESS: ON_FAILURE # Reuse the ON_FAILURE result definition

  - ON_FAILURE:
   # This step catches failures from the SSH operation itself OR non-zero command return codes
   do:
    io.cloudslang.base.utils.do_nothing: []
   navigate:
    - SUCCESS: FAILURE # Final workflow result

 outputs:
  - stdout:
    value: ${command_stdout}
    description: The standard output of the 'who' command.
  - stderr:
    value: ${command_stderr}
    description: The standard error output, if any.
  - return_code:
    value: ${command_return_code}
    description: The return code from the 'who' command execution (0 typically means success).
  - return_result:
    value: ${command_return_result}
    description: The result message from the underlying SSH operation.

 results:
  - SUCCESS: "Command 'who' executed successfully and returned code 0."
  - FAILURE: "Failed to execute command 'who' or SSH connection failed. Check return_code and stderr."

