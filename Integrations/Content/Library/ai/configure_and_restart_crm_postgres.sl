namespace: ai
flow:
  name: configure_and_restart_crm_postgres
  workflow:
    - modify_postgres_config:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
            - command: "sudo sed -i \"s/^\\(#\\?\\)max_locks_per_transaction\\s*=.*/max_locks_per_transaction = 30/\" /var/lib/pgsql/17/data/postgresql.conf"
            - pty: true
        publish:
          - config_update_result: '${return_result}'
          - config_update_error: '${stderr}'
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
            - pty: true
        publish:
          - service_restart_result: '${return_result}'
          - service_restart_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - config_update_result: '${config_update_result}'
    - config_update_error: '${config_update_error}'
    - service_restart_result: '${service_restart_result}'
    - service_restart_error: '${service_restart_error}'
  results:
    - SUCCESS
    - FAILURE
