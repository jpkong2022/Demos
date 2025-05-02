namespace: ai
flow:
  name: crm_server_maintenance
  workflow:
    - delete_jptmp_on_weblogic:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169  # CRM WebLogic Server IP
            - command: "sudo rm -rf /jptmp" # Command to delete directory from root
            - username: ec2-user          # CRM WebLogic Server Username
            - password:
                value: "Automation.123"  # CRM WebLogic Server Password
                sensitive: true
            - pty: true # May be needed for sudo without password prompt if configured
        publish:
          - delete_output: '${return_result}'
          - delete_return_code: '${return_code}'
          - delete_standard_err: '${standard_err}'
        navigate:
          - SUCCESS: add_user_on_postgres_server
          - FAILURE: on_failure

    - add_user_on_postgres_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            # NOTE: The CRM topology lists the same IP (172.31.28.169) for both weblogic and postgres servers.
            # Assuming the same credentials (ec2-user/Automation.123) apply for SSH access.
            # Also assuming ec2-user has sudo privileges to run commands as the postgres user.
            - host: 172.31.28.169  # CRM Postgres Server IP
            - command: "sudo -u postgres psql -c \"CREATE USER jp;\"" # Command to add user 'jp' in PostgreSQL
            - username: ec2-user          # CRM Postgres Server Username (assuming same as WebLogic)
            - password:
                value: "Automation.123"  # CRM Postgres Server Password (assuming same as WebLogic)
                sensitive: true
            - pty: true # May be needed for sudo without password prompt if configured
        publish:
          - adduser_output: '${return_result}'
          - adduser_return_code: '${return_code}'
          - adduser_standard_err: '${standard_err}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - delete_output: '${delete_output}'
    - delete_return_code: '${delete_return_code}'
    - delete_standard_err: '${delete_standard_err}'
    - adduser_output: '${adduser_output}'
    - adduser_return_code: '${adduser_return_code}'
    - adduser_standard_err: '${adduser_standard_err}'

  results:
    - SUCCESS
    - FAILURE
