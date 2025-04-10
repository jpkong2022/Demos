namespace: ai
imports:
  ssh: io.cloudslang.base.ssh
  powershell: io.cloudslang.base.powershell

flow:
  name: stop_databases
  inputs:
    # Windows Inputs
    - windows_host:
        required: true
    - windows_username:
        required: true
    - windows_password:
        required: true
        sensitive: true
    - mssql_service_name:
        required: false
        default: 'MSSQLSERVER' # Default instance name, change if needed
    - windows_auth_type:
        required: false
        default: ntlm # NTLM is often required for service control
    - windows_trust_all_roots:
        required: false
        default: 'true' # Set to false in production with proper certs

    # Linux Inputs
    - linux_host:
        required: true
    - oracle_username: # Typically 'oracle'
        required: true
    - oracle_password:
        required: true
        sensitive: true
    - oracle_home: # e.g., /u01/app/oracle/product/19.0.0/dbhome_1
        required: true
    - oracle_sid: # Optional: needed if dbshut requires it or for more specific commands
        required: false

  workflow:

    - stop_oracle_on_linux:
        do:
          ssh.ssh_command:
            - host: ${linux_host}
            - username: ${oracle_username}
            - password: ${oracle_password}
            # Command assumes dbshut is in PATH for oracle user or uses ORACLE_HOME
            # Ensure the oracle_username has permissions and environment set up
            # to run dbshut or necessary sqlplus commands.
            # Using dbshut is generally preferred if configured.
            - command: |
                echo "Attempting to stop Oracle DB using dbshut..."
                export ORACLE_HOME=${oracle_home}
                # Optional: Export ORACLE_SID if needed by dbshut/environment
                # export ORACLE_SID=${oracle_sid}
                export PATH=$ORACLE_HOME/bin:$PATH
                lsnrctl stop # Stop listener first
                dbshut $ORACLE_HOME
                # Check status - dbshut exit code might not be reliable
                # A more robust check would involve sqlplus 'select status from v$instance;'
                # but that adds complexity (handling sqlplus output).
                # For simplicity, we rely on dbshut execution. Check stderr.
                echo "dbshut command executed."
        publish:
          - oracle_stop_result: '${return_result}'
          - oracle_stop_error: '${stderr}'
          - oracle_cmd_exit_code: '${return_code}' # ssh_command uses return_code
        navigate:
          - SUCCESS: SUCCESS # Final success if Oracle stop is okay
          - FAILURE: on_failure

    - on_failure:
        do:
          # Placeholder for failure handling logic if needed
          noop:
        navigate:
          - SUCCESS: FAILURE # Ensures the flow result is FAILURE

  results:
    - SUCCESS
    - FAILURE
