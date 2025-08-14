namespace: ai
flow:
  name: configure_aos_db_max_locks_and_restart
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
            - script: >
                $configFile = "C:\Program Files\PostgreSQL\12\data\postgresql.conf" # Adjust path if necessary
                if (Test-Path $configFile) {
                    (Get-Content $configFile) -replace '^(#?)max_locks_per_transaction\s*=.*', 'max_locks_per_transaction = 30' | Set-Content $configFile
                    # Check if the line existed and was replaced. If not, add it.
                    if (-not (Select-String -Path $configFile -Pattern "^\s*max_locks_per_transaction")) {
                        Add-Content -Path $configFile -Value "max_locks_per_transaction = 30"
                    }
                    Write-Host "Configuration updated: max_locks_per_transaction set to 30 in $configFile"
                } else {
                    Write-Error "Configuration file not found at $configFile"
                    exit 1 # Exit with error code if file not found
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - config_update_result: '${return_result}'
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
        publish:
          - service_restart_result: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - config_update_result: '${config_update_result}'
    - service_restart_result: '${service_restart_result}'
  results:
    - SUCCESS
    - FAILURE
