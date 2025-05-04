namespace: ai
flow:
  name: configure_and_restart_aos_db
  inputs:
    - db_host:
        default: "172.31.26.86"
        required: false
    - db_admin_user:
        default: "administrator"
        required: false
    - db_admin_password:
        default: "*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV" # Consider using system properties for sensitive values
        required: true
        sensitive: true
    - db_service_name:
        default: "postgresql-x64-12"
        required: false
    - pg_user: # The PostgreSQL superuser to run ALTER SYSTEM
        default: "postgres"
        required: false
    - db_name: # The database to connect to initially (ALTER SYSTEM is cluster-wide)
        default: "postgres"
        required: false
    - max_locks_value:
        default: "10"
        required: false
    - winrm_port:
        default: "5985"
        required: false
    - winrm_protocol:
        default: "http"
        required: false
    - winrm_auth_type:
        default: "basic"
        required: false

  workflow:
    - set_max_locks:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: ${db_host}
            - port: ${winrm_port}
            - protocol: ${winrm_protocol}
            - username: ${db_admin_user}
            - password:
                value: ${db_admin_password}
                sensitive: true
            - auth_type: ${winrm_auth_type}
            # Assuming psql is in the PATH and appropriate HBA rules allow connection
            # The specific psql path might be needed if not in PATH
            # Authentication method (e.g., via .pgpass, trust, SSPI) needs to be configured on the server side
            # or password might need to be passed securely if using password auth.
            # Example assumes trust or integrated auth is configured for the admin user connecting locally.
            - script: |
                # Construct the command to execute via psql
                # Ensure quotes are handled correctly for PowerShell execution
                $sqlCommand = "ALTER SYSTEM SET max_locks_per_transaction = ${max_locks_value};"
                # Execute using psql. Adjust path if necessary.
                # Add - PGPASSWORD=... or other auth mechanisms if needed and secure.
                & "C:\Program Files\PostgreSQL\12\bin\psql.exe" -U "${pg_user}" -d "${db_name}" -c $sqlCommand
            - trust_all_roots: 'true' # Use with caution in production
            - x_509_hostname_verifier: 'allow_all' # Use with caution in production
        publish:
          - config_change_result: '${return_result}'
          - config_change_code: '${return_code}'
        navigate:
          - SUCCESS: restart_db_service
          - FAILURE: on_failure

    - restart_db_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: ${db_host}
            - port: ${winrm_port}
            - protocol: ${winrm_protocol}
            - username: ${db_admin_user}
            - password:
                value: ${db_admin_password}
                sensitive: true
            - auth_type: ${winrm_auth_type}
            - script: "Restart-Service -Name '${db_service_name}' -Force" # Use -Force if needed
            - trust_all_roots: 'true' # Use with caution in production
            - x_509_hostname_verifier: 'allow_all' # Use with caution in production
        publish:
          - restart_result: '${return_result}'
          - restart_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - config_change_result: '${config_change_result}'
    - config_change_code: '${config_change_code}'
    - restart_result: '${restart_result}'
    - restart_code: '${restart_code}'

  results:
    - SUCCESS
    - FAILURE
