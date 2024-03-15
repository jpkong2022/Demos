namespace: ai
flow:
  name: cli_operation
  workflow:
    - ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.75.22
            - command: whoami
            - username: centos
            - password:
                value: 'go.MF.admin123!'
                sensitive: true
        publish:
          - user: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE

