namespace: ai
flow:
  name: delete_jptmp_on_weblogic1
  workflow:
    - delete_jptmp_directory:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: "Automation.123"
                sensitive: true
            - command: "rm -rf /jptmp"
        publish:
          - command_output: '${return_result}'
          - return_code: '${return_code}' # Exit code of the ssh_command operation itself
          - standard_err: '${standard_err}' # stderr from the remote command
          - standard_out: '${standard_out}' # stdout from the remote command
          - command_return_code: '${command_return_code}' # Exit code of the remote command
          - exception: '${exception}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - command_output: '${command_output}'
    - error_output: '${standard_err}'
    - return_code: '${return_code}'
    - command_return_code: '${command_return_code}'
    - exception: '${exception}'
  results:
    - SUCCESS
    - FAILURE
