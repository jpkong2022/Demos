namespace: ai

flow:
 name: run_wc_command

 inputs:
  - host:
    description: Target host (IP address or FQDN) to run the wc command on.
    required: true
  - username:
    description: SSH username for the target host.
    required: true
  - password:
    description: SSH password for the target host. Use private_key_file for key-based auth.
    required: true
    sensitive: true
  # - private_key_file:
  #     description: Path to the private key file for SSH authentication. Use instead of password.
  #     required: false
  - file_path:
    description: The absolute path to the file on the target host to run wc against.
    required: true
  - wc_options:
    description: Optional arguments for the wc command (e.g., '-l', '-w', '-c').
    required: false
    default: ''
  - port:
    description: SSH port for the target host.
    required: false
    default: '22'
  - timeout:
    description: Timeout for the SSH command execution in milliseconds.
    required: false
    default: '90000' # 90 seconds

 workflow:
  - run_wc_on_target:
    do:
     io.cloudslang.base.ssh.ssh_command:
      - host: ${host}
      - port: ${port}
      - username: ${username}
      - password: ${password}
      # - private_key_file: ${private_key_file} # Uncomment if using key auth
      - command: ${'wc ' + (wc_options + ' ' if wc_options else '') + file_path}
      - timeout: ${timeout}
      - Pty: false # Typically not needed for non-interactive commands like wc
    publish:
     - wc_output: ${stdout}
     - error_message: ${stderr}
     - return_code: ${return_code}
     - return_result: ${return_result}
    navigate:
     - SUCCESS: ${return_code == '0'}
     - FAILURE: ${return_code != '0'}

 outputs:
  - wc_output:
    description: The standard output of the wc command.
    value: ${wc_output}
  - error_message:
    description: Any error output from the wc command or SSH execution.
    value: ${error_message}
  - return_code:
    description: The return code of the remote command execution (0 typically indicates success).
    value: ${return_code}

 results:
  - SUCCESS
  - FAILURE
