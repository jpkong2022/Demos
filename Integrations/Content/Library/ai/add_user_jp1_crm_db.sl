namespace: ai
flow:
  name: add_user_jp1_crm_db
  workflow:
    - add_postgres_user_jp1:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169 # IP address of the CRM Postgres server (oracleserver1)
            - username: ec2-user # Username for the Linux server hosting Postgres
            - password:
                value: "Automation.123" # Password for the Linux server hosting Postgres
                sensitive: true
            # Command to add user 'jp1'. Assumes ec2-user has passwordless sudo rights
            # to run commands as the 'postgres' OS user, and that the 'postgres' DB user
            # can connect locally without a password (peer/trust auth).
            - command: 'sudo -u postgres psql -c "CREATE USER jp1;"'
            - pty: false # Generally not needed for non-interactive commands
        publish:
          - command_output: '${return_result}'
          - return_code: '${return_code}' # Exit code of the ssh_command operation itself
          - command_return_code: '${command_return_code}' # Exit code of the remote command
          - standard_err: '${standard_err}'
          - standard_out: '${standard_out}'
        navigate:
          # Check command_return_code specifically for command success (0)
          - SUCCESS: check_command_success
          - FAILURE: on_failure # Failure of the SSH operation itself

    - check_command_success:
        do:
          io.cloudslang.base.utils.equals:
            - first: '${command_return_code}'
            - second: '0'
        navigate:
          - SUCCESS: SUCCESS # Command executed successfully (exit code 0)
          - FAILURE: on_failure # Command failed (non-zero exit code)

  outputs:
    - command_output: '${command_output}'
    - return_code: '${return_code}'
    - command_return_code: '${command_return_code}'
    - standard_err: '${standard_err}'
    - standard_out: '${standard_out}'

  results:
    - SUCCESS
    - FAILURE
