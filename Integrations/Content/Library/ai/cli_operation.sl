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
extensions:
  graph:
    steps:
      ssh_command:
        x: 160
        'y': 120
        navigate:
          d4766198-eb1f-d2b4-ea3a-51c87cefc1f4:
            targetId: 96abb0fa-ec51-b374-2a84-70ee86b28b62
            port: SUCCESS
    results:
      SUCCESS:
        96abb0fa-ec51-b374-2a84-70ee86b28b62:
          x: 360
          'y': 160
