namespace: ai
flow:
  name: restart_crm_database
  workflow:
    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            # Target the postgres linux server for CRM
            - host: 172.31.28.169
            # Use the provided username for the CRM postgres server host
            # Assuming the weblogic user 'ec2-user' has sudo rights on the db server,
            # or you would need a different user/method if permissions differ.
            # If the postgres server had a different user, you'd use that.
            # Let's assume ec2-user is used for simplicity based on the text structure,
            # but this might need adjustment in a real scenario if the postgres server
            # has different credentials.
            - username: ec2-user
            - password:
                value: 'Automation.123' # Password for ec2-user on 172.31.28.169
                sensitive: true
            # Command to restart the specific postgresql service identified for CRM
            # Using systemctl which is common on modern Linux. Requires sudo.
            - command: sudo systemctl restart postgresql-17
            # pty might be needed for sudo interactions, depending on sudoers config
            - pty: true
        publish:
          - restart_output: '${return_result}'
          - return_code: '${return_code}'
        navigate:
          # If the ssh command execution returns success (exit code 0), flow succeeds
          - SUCCESS: SUCCESS
          # If the ssh command fails (non-zero exit code, connection error, etc.), flow fails
          - FAILURE: on_failure
  outputs:
    - command_output: '${restart_output}'
    - return_code: '${return_code}'
  results:
    - SUCCESS
    - FAILURE
