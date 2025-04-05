namespace: ai

flow:
  name: run_who_command

  inputs:
    - host:
        required: true
        description: The hostname or IP address of the target Linux server.
    - port:
        default: 22
        required: false
        description: The SSH port to connect to. Defaults to 22.
    - username:
        required: true
        description: The username to connect as.
    - password:
        required: false
        sensitive: true
        description: The password for the user. Use password OR private_key_file.
    - private_key_file:
        required: false
        description: The path to the private SSH key file. Use password OR private_key_file.
    - timeout:
        default: 90000 # 90 seconds
        required: false
        description: Timeout for the SSH command execution in milliseconds.

  workflow:
    - execute_who:
        do:
          io.cloudslang.base.remote_command_execution.ssh_command:
            - host: ${host}
            - port: ${port}
            - username: ${username}
            - password: ${password}
            - private_key_file: ${private_key_file}
            - command: "who"
            - timeout: ${timeout}
        publish:
          - who_stdout: ${stdout}
          - who_stderr: ${stderr}
          - return_code: ${return_code}
          - exception: ${exception}
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE

  outputs:
    - who_output: ${who_stdout}
    - command_stderr: ${who_stderr}
    - command_return_code: ${return_code}
    - command_exception: ${exception}

  results:
    - SUCCESS
    - FAILURE
