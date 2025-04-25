namespace: ai
flow:
  name: run_uname_on_weblogicserver1
  workflow:
    - execute_uname_ssh:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - command: uname
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
        publish:
          - uname_output: '${return_result}'
          - return_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - uname_output: '${uname_output}'
    - return_code: '${return_code}'
  results:
    - SUCCESS
    - FAILURE
