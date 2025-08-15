namespace: ai
flow:
  name: stop_aos_and_crm_databases
  workflow:
    - stop_aos_postgres_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('aosdb_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: "Stop-Service -Name 'postgresql-x64-12'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: stop_crm_postgres_service
          - FAILURE: on_failure
    - stop_crm_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: "${get_sp('crmdb_admin_pwd')}"
                sensitive: true
            - command: "sudo systemctl stop postgresql-17"
            - pty: true
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
