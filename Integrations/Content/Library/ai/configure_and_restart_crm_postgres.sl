namespace: ai
flow:
  name: configure_and_restart_crm_postgres
  workflow:
    - set_max_locks_per_transaction:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: "Automation.123"
                sensitive: true
            # Command to find the line '#max_locks_per_transaction = 64' or 'max_locks_per_transaction = XX'
            # and replace it with 'max_locks_per_transaction = 30'. Uses sudo as config is likely root/postgres owned.
            # sed -i handles in-place edit. The regex handles commented or uncommented lines.
            - command: "sudo sed -i 's/^#*max_locks_per_transaction = .*/max_locks_per_transaction = 30/' /var/lib/pgsql/17/data/postgresql.conf"
            - pty: true # Often needed for sudo
        publish:
          - config_update_result: '${return_result}'
          - config_update_return_code: '${return_code}'
        navigate:
          - SUCCESS: restart_postgres_service
          - FAILURE: on_failure

    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: "Automation.123"
                sensitive: true
            # Command to restart the specific postgresql service. Requires sudo.
            - command: "sudo systemctl restart postgresql-17"
            - pty: true # Often needed for sudo/systemctl
        publish:
          - restart_result: '${return_result}'
          - restart_return_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - config_update_return_code: '${config_update_return_code}'
    - restart_return_code: '${restart_return_code}'
    - config_update_result: '${config_update_result}'
    - restart_result: '${restart_result}'

  results:
    - SUCCESS
    - FAILURE
