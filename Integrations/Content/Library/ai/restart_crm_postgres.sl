namespace: ai
flow:
  name: restart_crm_postgres
  workflow:
    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169  # IP of oracleserver1 (where CRM Postgres runs)
            - port: 22             # Default SSH port
            - username: ec2-user     # Linux server username
            - password:
                value: 'Automation.123' # Linux server password
                sensitive: true
            - command: 'sudo systemctl restart postgresql-17' # Command to restart the specific service
            - pty: true            # Request pseudo-terminal, often needed for sudo
            - timeout: 90000       # Optional: timeout in milliseconds (90 seconds)
        publish:
          - restart_output: '${return_result}' # Output from the command
          - return_code: '${return_code}'     # Exit code of the command
        navigate:
          - SUCCESS: check_restart_status # Proceed if command execution succeeded (exit code 0 usually)
          - FAILURE: on_failure          # Go to failure handler if SSH fails or command returns non-zero exit code

    # Optional: Add a step to verify the service status after restart
    - check_restart_status:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - port: 22
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
            - command: 'systemctl is-active postgresql-17' # Check if the service is active
            - pty: true
            - timeout: 30000 # 30 seconds timeout
        publish:
          - service_status: '${return_result}'
          - status_check_return_code: '${return_code}'
        navigate:
          # systemctl is-active returns 0 and prints "active" if service is running
          - SUCCESS: SUCCESS # If status check command ran successfully (check output below)
          - FAILURE: on_failure

    # Note: You might want more sophisticated checking based on the output 'service_status'
    #       For example, use a script step to check if 'service_status' contains 'active'.
    #       This basic example just proceeds to SUCCESS if the *command itself* ran without error.

  outputs:
    - restart_output: '${restart_output}'
    - return_code: '${return_code}'
    - service_status: '${service_status}' # Output from the status check command
    - status_check_return_code: '${status_check_return_code}'

  results:
    - SUCCESS
    - FAILURE
