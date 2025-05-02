namespace: ai
flow:
  name: restart_crm_postgres_service
  workflow:
    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - command: sudo systemctl restart postgresql-17 # Assuming systemd is used and ec2-user has sudo rights
            - username: ec2-user
            - password:
                value: Automation.123
                sensitive: true
        publish:
          - command_output: '${return_result}'
          - return_code: '${return_code}'
          - standard_err
          - standard_out
        navigate:
          # As requested, navigating directly to SUCCESS without checking return code
          - SUCCESS: SUCCESS
          # Still good practice to include a failure path
          - FAILURE: on_failure
  outputs:
    - command_output: '${command_output}'
    - return_code: '${return_code}'
    - standard_err: '${standard_err}'
    - standard_out: '${standard_out}'
  results:
    - SUCCESS
    - FAILURE
