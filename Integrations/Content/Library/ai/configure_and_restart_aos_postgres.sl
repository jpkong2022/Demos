namespace: ai
flow:
  name: configure_and_restart_aos_postgres
  workflow:
    - modify_postgres_config_aos:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV'
                sensitive: true
            - auth_type: basic
            - script: "$configFile = \"C:\\Program Files\\PostgreSQL\\12\\data\\postgresql.conf\" # Assuming standard path for version 12
if (Test-Path $configFile) {
    (Get-Content $configFile) -replace '^(#?)max_locks_per_transaction\s*=.*', 'max_locks_per_transaction = 10' | Set-Content $configFile -Force
    Write-Host \"Configuration updated in $configFile\"
} else {
    Write-Error \"Configuration file not found at $configFile\"
    # Optionally exit with error code, but request said no need to check success
    # exit 1 
}"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - config_update_result: '${return_result}'
          - config_update_error: '${stderr}'
        navigate:
          - SUCCESS: restart_postgres_service_aos
          - FAILURE: on_failure # Standard failure path
    - restart_postgres_service_aos:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV'
                sensitive: true
            - auth_type: basic
            - script: "Restart-Service -Name 'postgresql-x64-12' -Force"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - service_restart_result: '${return_result}'
          - service_restart_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS # Navigate directly to SUCCESS
          - FAILURE: on_failure # Standard failure path
  outputs:
    - config_update_result: '${config_update_result}'
    - config_update_error: '${config_update_error}'
    - service_restart_result: '${service_restart_result}'
    - service_restart_error: '${service_restart_error}'
  results:
    - SUCCESS
    - FAILURE
