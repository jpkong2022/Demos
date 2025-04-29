namespace: ai
flow:
  name: stop_aos_database_server
  workflow:
    - stop_postgres_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86                  # postgresserver1 IP address
            - port: '5985'                        # Default WinRM HTTP port
            - protocol: http                      # Assuming HTTP WinRM
            - username: administrator             # Username for postgresserver1
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # Password for postgresserver1
                sensitive: true
            - auth_type: basic                    # Basic authentication
            - script: Stop-Service -Name "postgresql-x64-12" # Command to stop the specific service
            - trust_all_roots: 'true'             # As per example, often needed for non-domain WinRM
            - x_509_hostname_verifier: allow_all  # As per example
        publish:
          - stop_result: '${return_result}'
          - return_code: '${return_code}'
          - error_message: '${error_message}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - stop_result: '${stop_result}'
    - return_code: '${return_code}'
    - error_message: '${error_message}'
  results:
    - SUCCESS
    - FAILURE
