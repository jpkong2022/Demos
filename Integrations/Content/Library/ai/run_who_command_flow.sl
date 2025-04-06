namespace: ai

imports:
 ssh: io.cloudslang.base.remote

flow:
 name: run_who_command_flow

 inputs:
  - host:
    required: true
    description: The target host (IP or FQDN) to run the 'who' command on.
  - username:
    required: true
    description: The username for SSH login.
  - password:
    required: true
    sensitive: true
    description: The password for SSH login.
  # Optional inputs for SSH connection (can add private_key_file etc. if needed)
  - port:
    default: "22"
    description: The SSH port.
  - timeout:
    default: "90000" # 90 seconds
    description: SSH connection timeout in milliseconds.

 workflow:
  - run_the_who_command:
    do:
     ssh.ssh_command:
      - host: ${host}
      - port: ${port}
      - username: ${username}
      - password: ${password}
      - command: "who"
      - timeout: ${timeout}
    publish:
     - command_output: ${return_result} # Standard output of the command
     - return_code: ${return_code}     # Exit code of the command
     - error_message: ${error_message} # Any error message captured
    navigate:
     - SUCCESS: SUCCESS
     - FAILURE: FAILURE

 outputs:
  - who_command_output: ${command_output}
  - command_exit_code: ${return_code}
  - ssh_error_message: ${error_message}

 results:
  - SUCCESS
  - FAILURE
