namespace: ai
flow:
  name: execute_who_on_weblogicserver1
  workflow:
    - ssh_command_on_weblogic1:
        do:
          io.cloudslang.base.ssh.ssh_command:
            # Target server details from the provided topology
            - host: 172.31.28.169  # IP address of weblogicserver1
            - command: who         # The command to execute
            # --- Authentication - Replace with actual credentials or use inputs ---
            - username: <your_linux_username> # Replace with the appropriate username for weblogicserver1
            - password:
                value: '<your_linux_password>' # Replace with the appropriate password
                sensitive: true
            # Optional parameters (can be added if needed)
            # - port: 22
            # - timeout: 90000
            # - pty: false
        publish:
          - command_output: '${return_result}' # The output of the 'who' command
          - return_code: '${return_code}'       # The exit code of the ssh operation
        navigate:
          - SUCCESS: SUCCESS # If the command executes successfully, end flow successfully
          - FAILURE: on_failure # If command execution fails, go to standard failure handling
  outputs:
    # Optional: Expose the command output from the flow level
    - command_output: '${command_output}'
    - return_code: '${return_code}'
  results:
    - SUCCESS # Represents a successful execution of the flow
    - FAILURE # Represents a failed execution of the flow
