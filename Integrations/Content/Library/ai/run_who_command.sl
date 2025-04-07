namespace: ai

imports:
 remote_command: io.cloudslang.base.remote_command

flow:
 name: run_who_command

 inputs:
  - host:
    required: true
    description: The target host or IP address to run the 'who' command on.
  - username:
    required: true
    description: The username for the SSH connection.
  - password:
    required: true
    sensitive: true
    description: The password for the SSH connection.
  # Optional: Add private_key_file input if using key-based authentication
  # - private_key_file:
  #     description: The path to the private key file for SSH connection.
  # Optional: Add port input if not using the default SSH port 22
  # - port:
  #     default: '22'
  #     description: The SSH port number.

 workflow:
  - execute_who_command:
    do:
     # Assumes io.cloudslang.base content pack is deployed
     remote_command.cmd_runner:
      - host: ${host}
      - username: ${username}
      - password: ${password}
      # Uncomment and use if using private key auth instead of password
      # - private_key_file: ${private_key_file}
      # Uncomment if using a non-default port
      # - port: ${port}
      - command: "who"
    publish:
     - command_output: ${return_result} # Raw output from cmd_runner

 results:
  - SUCCESS
  - FAILURE
