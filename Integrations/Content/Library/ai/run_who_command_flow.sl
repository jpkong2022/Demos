namespace: ai
flow:
 name: run_who_command_flow

 inputs:
  - host
  - password
    description
  - port
  - timeout

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
