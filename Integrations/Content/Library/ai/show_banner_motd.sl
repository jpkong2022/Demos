namespace: ai
flow:
  name: show_banner_motd
  inputs:
    - host:
        required: true
    - port:
        default: 22
        required: false
    - username:
        required: true
    - password:
        required: true
        sensitive: true
    - timeout:
        default: 90000 # Default timeout 90 seconds
        required: false
  workflow:
    - execute_show_banner:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${host}'
            - port: '${port}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - command: 'show banner motd'
            - pty: true  # Often needed for interactive-like sessions on network devices
            - timeout: '${timeout}'
        publish:
          - banner_output: '${return_result}' # The command output
          - return_code: '${return_code}'     # The exit code of the command execution itself
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - banner_output: '${banner_output}'
    - return_code: '${return_code}'
  results:
    - SUCCESS
    - FAILURE
