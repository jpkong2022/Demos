namespace:ai
flow:
  name: cleanup2
  inputs:
    - host
    - username
    - password
  workflow:
    - ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - command: "rm -rf /tmp/*"
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
        publish:
          - cleanup_result: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  results:
    - SUCCESS
    - FAILURE