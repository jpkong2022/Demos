namespace: ai
flow:
  name: restart_aos_database_server
  workflow:
    - restart_postgres_service:
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
            - script: "Restart-Service -Name 'postgresql-x64-12'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
