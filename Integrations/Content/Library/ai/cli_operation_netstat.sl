namespace: ai
flow:
  name: cli_operation_netstat
  workflow:
    - ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169  # Replace with your Linux host IP
            - command: "netstat -tuln | grep ':80 ' | wc -l"
            - username: ec2-user  # Replace with your SSH username
            - password:
                value: 'Automation.123'  # Replace with your SSH password
                sensitive: true
        publish:
          - port_80_open: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  results:
    - SUCCESS
    - FAILURE