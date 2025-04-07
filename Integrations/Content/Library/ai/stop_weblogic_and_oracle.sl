namespace: ai

imports:
  ssh: io.cloudslang.base.ssh

flow:
  name: stop_weblogic_and_oracle

  inputs:
    # WebLogic Inputs
    - wl_host:
        required: true
        description: IP address or hostname of the WebLogic application server.
    - wl_username:
        required: true
        description: SSH username for the WebLogic server.
    - wl_password:
        required: true
        sensitive: true
        description: SSH password for the WebLogic server.
    - wl_stop_script_path:
        required: true
        description: Full path to the WebLogic stop script (e.g., /opt/oracle/domains/mydomain/bin/stopWebLogic.sh or stopManagedWebLogic.sh).
    # Oracle DB Inputs
    - db_host:
        required: true
        description: IP address or hostname of the Oracle database server.
    - db_username:
        required: true
        description: SSH username for the Oracle database server (e.g., oracle).
    - db_password:
        required: true
        sensitive: true
        description: SSH password for the Oracle database server.
    - oracle_home:
        required: true
        description: The ORACLE_HOME path on the database server.
    - oracle_sid:
        required: true
        description: The ORACLE_SID for the database to stop.

  workflow:
    - stop_weblogic_server:
        do:
          ssh.ssh_command:
            - host: ${wl_host}
            - username: ${wl_username}
            - password:
                value: ${wl_password}
                sensitive: true
            - command: ${wl_stop_script_path} # Execute the provided stop script
            - timeout: '120000' # Optional: 2-minute timeout
        publish:
          - wl_stop_output: ${return_result}
          - wl_stop_exit_code: ${return_code}
        navigate:
          - SUCCESS: stop_oracle_database # Proceed to stop DB on success
          - FAILURE: on_failure

    - stop_oracle_database:
        do:
          ssh.ssh_command:
            - host: ${db_host}
            - username: ${db_username}
            - password:
                value: ${db_password}
                sensitive: true
            # Command to set environment and stop Oracle via SQL*Plus
            # Assumes OS authentication (/ as sysdba) is configured
            - command: |
                export ORACLE_HOME=${oracle_home};
                export ORACLE_SID=${oracle_sid};
                echo "SHUTDOWN IMMEDIATE;" | ${oracle_home}/bin/sqlplus -S / as sysdba
            - timeout: '180000' # Optional: 3-minute timeout
        publish:
          - db_stop_output: ${return_result}
          - db_stop_exit_code: ${return_code}
        navigate:
          - SUCCESS: SUCCESS # Final success if DB stops okay
          - FAILURE: on_failure

  outputs:
    - weblogic_stop_result: ${wl_stop_output}
    - weblogic_stop_exit_code: ${wl_stop_exit_code}
    - oracle_db_stop_result: ${db_stop_output}
    - oracle_db_stop_exit_code: ${db_stop_exit_code}

  results:
    - SUCCESS
    - FAILURE
