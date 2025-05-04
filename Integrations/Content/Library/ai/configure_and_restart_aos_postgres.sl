namespace: ai
flow:
  name: configure_and_restart_aos_postgres
  workflow:
    - modify_postgres_config:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86              # AOS Postgresql windows server IP
            - port: '5985'                   # Default WinRM HTTP port
            - protocol: http
            - username: administrator        # AOS Postgresql windows server username
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # AOS Postgresql windows server password
                sensitive: true
            - auth_type: basic
            - script: |
                # Define the path to the PostgreSQL configuration file.
                # NOTE: Adjust this path if your PostgreSQL installation differs.
                # Common locations are within Program Files or ProgramData.
                $configFile = "C:\Program Files\PostgreSQL\12\data\postgresql.conf"

                # Check if the configuration file exists
                if (Test-Path $configFile) {
                    # Read the content, replace the specific line, and write it back
                    (Get-Content $configFile) -replace '^(#?)max_locks_per_transaction\s*=.*', 'max_locks_per_transaction = 10' | Set-Content $configFile
                    Write-Host "Configuration updated: max_locks_per_transaction set to 10 in $configFile"
                } else {
                    Write-Error "Configuration file not found at $configFile"
                    # Exit with a non-zero code to indicate failure
                    exit 1
                }
            - trust_all_roots: 'true'          # Use 'true' for lab/dev, review for production
            - x_509_hostname_verifier: allow_all # Use 'allow_all' for lab/dev, review for production
        publish:
          - config_update_result: '${return_result}' # Output from the script (stdout)
          - config_update_error: '${stderr}'         # Any errors written to stderr
        navigate:
          - SUCCESS: restart_postgres_service # If script exits with code 0, proceed
          - FAILURE: on_failure               # If script fails (non-zero exit or connection error)

    - restart_postgres_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86              # AOS Postgresql windows server IP
            - port: '5985'
            - protocol: http
            - username: administrator        # AOS Postgresql windows server username
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # AOS Postgresql windows server password
                sensitive: true
            - auth_type: basic
            - script: "Restart-Service -Name 'postgresql-x64-12' -Force" # AOS Postgres windows service name
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - service_restart_result: '${return_result}'
          - service_restart_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS                    # If Restart-Service succeeds
          - FAILURE: on_failure               # If Restart-Service fails

  outputs:
    - config_update_result: '${config_update_result}'
    - config_update_error: '${config_update_error}'
    - service_restart_result: '${service_restart_result}'
    - service_restart_error: '${service_restart_error}'

  results:
    - SUCCESS # Final success state
    - FAILURE # Final failure state, reachable from any step's on_failure
