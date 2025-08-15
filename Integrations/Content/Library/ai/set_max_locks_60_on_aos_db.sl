namespace: ai
flow:
  name: set_max_locks_60_on_aos_db
  workflow:
    - modify_postgres_config:
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
            - script: |
                $configFile = "C:\Program Files\PostgreSQL\12\data\postgresql.conf"
                if (Test-Path $configFile) {
                    (Get-Content $configFile) -replace '^(#?)max_locks_per_transaction\s*=.*', 'max_locks_per_transaction = 60' | Set-Content $configFile
                    Write-Host "Configuration updated in $configFile"
                } else {
                    Write-Error "Configuration file not found at $configFile"
                    exit 1
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: restart_postgres_service
          - FAILURE: on_failure
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
