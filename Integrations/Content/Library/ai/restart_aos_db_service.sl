namespace: ai
flow:
  name: restart_aos_db_service
  workflow:
    - restart_postgres_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            # Target the AOS PostgreSQL Windows server
            - host: 172.31.26.86
            - port: '5985' # Default WinRM HTTP port
            - protocol: http
            # Credentials for the AOS PostgreSQL server
            - username: administrator
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV'
                sensitive: true
            - auth_type: basic # Assuming basic auth, adjust if NTLM/Kerberos needed
            # PowerShell command to restart the specific PostgreSQL service for AOS
            - script: 'Restart-Service -Name "postgresql-x64-12"'
            # Configuration often needed for WinRM, especially non-domain/self-signed certs
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - restart_output: '${return_result}' # Capture command output
          - restart_return_code: '${return_code}' # Capture exit code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - restart_output: '${restart_output}'
    - restart_return_code: '${restart_return_code}'
  results:
    - SUCCESS
    - FAILURE
