namespace: ai
flow:
  name: restart_crm_database_server
  workflow:
    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
            # Using sudo to restart the service, assuming ec2-user has passwordless sudo rights
            - command: "sudo systemctl restart postgresql-17"
        publish:
          - restart_output: '${return_result}'
          - restart_error: '${stderr}'
          - return_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - restart_output: '${restart_output}'
    - restart_error: '${restart_error}'
    - return_code: '${return_code}'
  results:
    - SUCCESS
    - FAILURE
