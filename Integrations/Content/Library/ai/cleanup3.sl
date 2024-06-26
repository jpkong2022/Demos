namespace: ai

flow:
  name: cleanup3
  inputs:
    - host
    - sshUsername
    - sshPassword
  workflow:
    - ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${host}'
            - command: "rm -rf /tmp/*"
            - username: '${sshUsername}'
            - password:
                value: '${sshPassword}'
                sensitive: true
        publish:
          - cleanup_result: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  results:
    - SUCCESS
    - FAILURE