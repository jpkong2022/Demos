namespace: ai
flow:
  name: restart_crm_database
  workflow:
    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: "${get_sp('crmdb_admin_pwd')}"
                sensitive: true
            - command: "sudo systemctl restart postgresql-17"
            - pty: true
        publish:
          - restart_output: '${return_result}'
          - return_code: '${return_code}'
          - restart_error: '${stderr}'
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
