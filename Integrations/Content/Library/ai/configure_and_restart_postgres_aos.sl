namespace: ai
flow:
  name: configure_and_restart_postgres_aos
  workflow:
    - modify_postgres_config:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86 # postgresserver1 IP for AOS
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # Password for postgresserver1
                sensitive: true
            - auth_type: basic
            # Note: The exact path to postgresql.conf can vary depending on the installation.
            # Assuming a common path for PostgreSQL 12 on Windows. Adjust if needed.
            # This script finds the line starting with 'max_locks_per_transaction' (optionally commented out)
            # and replaces it with the desired setting. If the line doesn't exist, it won't add it.
            # For a more robust solution, check if the line exists and add/modify accordingly.
            - script: |
                $configFile = "C:\Program Files\PostgreSQL\12\data\postgresql.conf" # Adjust path if necessary
                if (Test-Path $configFile) {
                    (Get-Content $configFile) -replace '^(#?)max_locks_per_transaction\s*=.*', 'max_locks_per_transaction = 10' | Set-Content $configFile
                    Write-Host "Configuration updated in $configFile"
                } else {
                    Write-Error "Configuration file not found at $configFile"
                    exit 1 # Exit with error code if file not found
                }
            - trust_all_roots: 'true' # Use 'false' in production with proper certificate setup
            - x_509_hostname_verifier: allow_all # Use 'strict' in production
        publish:
          - config_update_result: '${return_result}'
          - config_update_error: '${error_message}'
        navigate:
          - SUCCESS: restart_postgres_service
          - FAILURE: on_failure

    - restart_postgres_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86 # postgresserver1 IP for AOS
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # Password for postgresserver1
                sensitive: true
            - auth_type: basic
            - script: "Restart-Service -Name 'postgresql-x64-12'" # Service name for AOS Postgres
            - trust_all_roots: 'true' # Use 'false' in production
            - x_509_hostname_verifier: allow_all # Use 'strict' in production
        publish:
          - service_restart_result: '${return_result}'
          - service_restart_error: '${error_message}'
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
