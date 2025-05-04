namespace: ai
flow:
  name: configure_and_restart_postgres_aos
  workflow:
    - modify_postgres_config:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86              # AOS Postgres Server IP
            - port: '5985'                   # Default WinRM HTTP port
            - protocol: http                 # Using HTTP as per example
            - username: administrator
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # AOS Postgres Admin Password
                sensitive: true
            - auth_type: basic               # Basic authentication
            - script: |
                # Define the path to the PostgreSQL configuration file
                # Adjust this path if your PostgreSQL 12 installation differs
                $configFile = "C:\Program Files\PostgreSQL\12\data\postgresql.conf"

                # Check if the configuration file exists
                if (Test-Path $configFile) {
                    # Read the content, replace the line, and write it back
                    (Get-Content $configFile) -replace '^(#?)max_locks_per_transaction\s*=.*', 'max_locks_per_transaction = 10' | Set-Content $configFile
                    Write-Host "Configuration updated: 'max_locks_per_transaction' set to 10 in $configFile"
                } else {
                    Write-Error "Configuration file not found at $configFile"
                    exit 1 # Exit with an error code if the file is not found
                }
            - trust_all_roots: 'true'        # Use with caution, ideally use proper certs
            - x_509_hostname_verifier: allow_all # Use with caution
        publish:
          - config_update_result: '${return_result}' # Capture standard output
          - config_update_error: '${stderr}'         # Capture standard error
        navigate:
          - SUCCESS: restart_postgres_service  # If successful, proceed to restart
          - FAILURE: on_failure             # If failed, go to failure handler
    - restart_postgres_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86              # AOS Postgres Server IP
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # AOS Postgres Admin Password
                sensitive: true
            - auth_type: basic
            - script: "Restart-Service -Name 'postgresql-x64-12'" # AOS Postgres Service Name
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - service_restart_result: '${return_result}' # Capture standard output
          - service_restart_error: '${stderr}'         # Capture standard error
        navigate:
          - SUCCESS: SUCCESS                  # If successful, the flow ends successfully
          - FAILURE: on_failure             # If failed, go to failure handler

  outputs: # Define outputs available from the flow
    - config_update_result: '${config_update_result}'
    - config_update_error: '${config_update_error}'
    - service_restart_result: '${service_restart_result}'
    - service_restart_error: '${service_restart_error}'

  results: # Define the possible end states of the flow
    - SUCCESS
    - FAILURE
