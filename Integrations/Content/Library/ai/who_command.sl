namespace: ai

flow:
  name: who_command

  workflow:
    - ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            # IMPORTANT: Replace with your actual target host IP
            - host: 172.31.75.22 
            # The command to execute
            - command: who 
            # IMPORTANT: Replace with your actual SSH username
            - username: centos 
            # IMPORTANT: Replace with your actual SSH password or use key-based auth
            - password:
                value: 'go.MF.admin123!' 
                sensitive: true
        publish:
          # Publish the command output (stdout) into a flow variable
          - who_output: '${return_result}' 
        navigate:
          # If the SSH command succeeds, transition to the flow's SUCCESS result
          - SUCCESS: SUCCESS
          # If the SSH command fails, transition to the flow's FAILURE result 
          # (assuming no 'on_failure' step is defined)
          - FAILURE: FAILURE 

  results:
    - SUCCESS
    - FAILURE
