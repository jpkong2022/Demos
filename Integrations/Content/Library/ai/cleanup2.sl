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
            - host: '${host}'
            - command: "rm -rf /tmp/*"
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
        publish:
          - cleanup_result: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  results:
    - SUCCESS
    - FAILURE