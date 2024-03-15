namespace: ai
flow:
  name: cli_operation
  workflow:
    - ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.75.22  # Replace with your Linux host IP
            - command: "top -bn1"
            - username: centos  # Replace with your SSH username
            - password:
                value: 'go.MF.admin123!'  # Replace with your SSH password
                sensitive: true
        publish:
          - cpu_utilization: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  results:
    - SUCCESS
    - FAILURE

