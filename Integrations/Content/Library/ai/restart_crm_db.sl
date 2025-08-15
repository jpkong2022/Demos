namespace: ai
flow:
  name: restart_crm_db
  workflow:
    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - command: sudo systemctl restart postgresql-17
            - username: ec2-user
            - password:
                value: "${get_sp('crmdb_admin_pwd')}"
                sensitive: true
            - pty: true
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
