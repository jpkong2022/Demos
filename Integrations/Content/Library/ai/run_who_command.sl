namespace: ai

imports:
  ssh: io.cloudslang.base.ssh

flow:
  name: run_who_command

  inputs:
    - host:
        description: The hostname or IP address of the target Linux server.
        required: true
    - username:
        description: The username to connect as.
        required: true
    - password:
        description: The password for the user. Use private_key_file for key-based auth.
        required: true
        sensitive: true
    - port:
        description: The SSH port on the target server.
        default: '22'
        required: false
    - timeout:
        description: SSH connection timeout in milliseconds.
        default: '90000'
        required: false
    # Add private_key_file input if using key-based authentication instead of password
    # - private_key_file:
    #     description: The path to the private key file for SSH authentication.
    #     required: false

  workflow:
    - execute_who:
        do:
          ssh.ssh_command:
            - host: ${host}
            - port: ${port}
            - username: ${username}
            - password: ${password}
            # - private_key_file: ${private_key_file} # Uncomment if using key auth
            - command: "who"
            - timeout: ${timeout}
            - pty: "false" # Generally not needed for non-interactive commands like 'who'
        publish:
          - stdout
          - stderr
          - return_code
          - exception
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: ON_FAILURE

  outputs:
    - stdout:
        description: The standard output of the 'who' command.
        value: ${stdout}
    - stderr:
        description: The standard error output, if any.
        value: ${stderr}
    - return_code:
        description: The return code of the command execution (0 usually indicates success).
        value: ${return_code}
    - exception:
        description: Any exception message encountered during execution.
        value: ${exception}

  results:
    - SUCCESS: ${return_code == '0'}
    - FAILURE # Implicitly handles non-zero return codes and exceptions via ON_FAILURE branch
