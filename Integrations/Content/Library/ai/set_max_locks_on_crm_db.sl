namespace: ai
flow:
  name: set_max_locks_on_crm_db
  workflow:
    - modify_postgres_config:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
            - command: "sudo sed -i \"s/^\\(#\\?\\)\\s*max_locks_per_transaction\\s*=.*/max_locks_per_transaction = 80/\" /var/lib/pgsql/17/data/postgresql.conf"
        navigate:
          - SUCCESS: restart_postgres_service
          - FAILURE: on_failure
    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
            - command: "sudo systemctl restart postgresql-17"
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
