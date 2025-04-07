namespace: ai

flow:
  name: delete_tmp_files

  workflow:
    - delete_files_step:
        do:
          io.cloudslang.base.ssh.ssh_command:
            # --- IMPORTANT: Replace these connection details ---
            - host: 172.31.75.22         # Target Linux host IP or FQDN
            - username: centos            # SSH username
            - password:                 # SSH password (consider using private_key_file for better security)
                value: 'go.MF.admin123!'  # Replace with actual password or remove if using private key
                sensitive: true
            # - private_key_file: /path/to/your/private/key # Alternative to password
            # ----------------------------------------------------
            - command: rm -rf /tmp/*      # Command to delete all files/dirs inside /tmp
            # Optional: Add timeout if deletion might take long
            # - timeout: '120000' # e.g., 120 seconds in milliseconds

        publish:
          # Publish the standard output (usually empty for rm -rf unless errors occur)
          - command_output: '${return_result}'
          # Publish the return code (0 typically means success for rm)
          - return_code: '${return_code}'

        navigate:
          # If ssh_command operation itself succeeds (command executed, exit code 0), flow is SUCCESS
          - SUCCESS: SUCCESS
          # If ssh_command fails (connection error, command execution error, non-zero exit code), flow is FAILURE
          - FAILURE: FAILURE # You could add an 'on_failure' step here for specific error handling

  results:
    - SUCCESS # Indicates the rm command was executed successfully (returned exit code 0)
    - FAILURE # Indicates an error during connection or command execution
