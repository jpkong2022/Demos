namespace: ai
flow:
  name: stop_crm_database
  workflow:
    - stop_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169  # IP address of the postgres linux server for CRM
            - port: 22            # Default SSH port
            - username: ec2-user  # Username for the server
            - password:
                value: "Automation.123" # Password for the server
                sensitive: true
            - command: "sudo systemctl stop postgresql-17" # Command to stop the specific postgres service
            - pty: true           # Request pseudo-terminal, might be needed for sudo
            - timeout: 90000      # Optional timeout in milliseconds
        publish:
          - stop_command_output: '${return_result}' # Output of the stop command
          - ssh_return_code: '${return_code}'       # Return code of the SSH operation itself
          - command_stderr: '${standard_err}'     # Standard error from the command
          - command_exit_code: '${command_return_code}' # Exit code of the remote command
        navigate:
          - SUCCESS: check_stop_status # If SSH command executed, check the actual command exit code
          - FAILURE: on_failure       # If SSH connection failed etc.
    - check_stop_status:
        do:
          io.cloudslang.base.utils.equals: # Check if the command exit code was 0 (success)
            - first: '${command_exit_code}'
            - second: '0'
        navigate:
          - SUCCESS: SUCCESS # Command succeeded
          - FAILURE: on_failure # Command failed (non-zero exit code)

  outputs:
    - stop_command_output: '${stop_command_output}'
    - ssh_return_code: '${ssh_return_code}'
    - command_stderr: '${command_stderr}'
    - command_exit_code: '${command_exit_code}'

  results:
    - SUCCESS
    - FAILURE
