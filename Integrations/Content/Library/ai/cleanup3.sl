namespace: ai

flow:
  name: cleanup3
  inputs:
    - host:
        description: The hostname or IP address of the server to ping.
        required: true
    - ping_count:
        description: Number of ping packets to send.
        required: false
        default: '4' # Default to 4 pings like standard ping command
    - timeout:
        description: Timeout in milliseconds to wait for each reply.
        required: false
        default: '5000' # Default to 5 seconds
  workflow:
    - ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${host}
            - command: "rm -rf /tmp/*"
            - username: ${sshUsername}
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