namespace: ai
flow:
  name: restart_crm_postgres
  workflow:
    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            # Target the CRM postgres server identified in the topology
            - host: 172.31.28.169
            # Use the provided credentials for the Linux server at that IP
            - username: ec2-user
            - password:
                value: 'Automation.123' # Use single quotes for YAML string containing special chars
                sensitive: true
            # Command to restart the specific postgresql service identified
            # Assumes systemd is used and ec2-user has passwordless sudo rights for this command
            - command: 'sudo systemctl restart postgresql-17'
            # Optional: pty might be needed for sudo in some configurations
            - pty: true
            # Optional: Set a timeout (e.g., 90 seconds)
            - timeout: 90000
        publish:
          - restart_output: '${return_result}' # Capture command output
          - return_code: '${return_code}'     # Capture exit code
        navigate:
          # Check the return code from the ssh_command operation itself
          - SUCCESS: check_command_exit_code
          - FAILURE: on_failure # Handle SSH connection failures etc.

    - check_command_exit_code:
        do:
          io.cloudslang.base.utils.equals:
             - first: '${return_code}'
             - second: '0' # Command executed successfully if exit code is 0
        navigate:
          - SUCCESS: SUCCESS # Command succeeded, flow is successful
          - FAILURE: on_failure # Command failed (non-zero exit code)

  outputs:
    - restart_output: '${restart_output}'
    - return_code: '${return_code}'

  results:
    - SUCCESS
    - FAILURE # Represents both SSH failures and command execution failures
