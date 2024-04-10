namespace: ai
flow:
  name: cleanup
  inputs:
   - token
   - host
   - sshUsername
   - sshPassword
  workflow:
    - ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169  # Replace with your Linux host IP
            - command: "rm -rf /tmp/*"
            - username: ec2-user  # Replace with your SSH username
            - password:
                value: 'Automation.123'  # Replace with your SSH password
                sensitive: true
        publish:
          - result: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  results:
    - SUCCESS
    - FAILURE