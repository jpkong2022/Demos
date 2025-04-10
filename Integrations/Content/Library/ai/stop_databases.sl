# CloudSlang Workflow to stop MSSQL on Windows and Oracle on Linux
namespace: ai

flow:
  name: stop_databases

  workflow:
    # Step 1: Stop MSSQL Service on Windows Server
    - stop_mssql_windows:
        do:
          # Uses PowerShell Remoting to execute the command on the target Windows server
          io.cloudslang.base.powershell.powershell_script:
            # --- Inputs for Windows Server ---
            # Replace with actual Windows host IP or FQDN
            - host: 192.168.1.100
            # Replace with actual Windows username with permissions to stop services
            - username: Administrator
            # Replace with actual Windows password
            - password:
                value: 'YourWindowsPassword!'
                sensitive: true
            # Authentication type (e.g., basic, ntlm, kerberos) - adjust as needed for your environment
            - auth_type: basic
            # PowerShell command to stop the MSSQL service (default instance name is MSSQLSERVER)
            # Adjust service name if using a named instance (e.g., MSSQL$SQLEXPRESS)
            # -ErrorAction Stop ensures the step fails if the command errors out
            - script: "Stop-Service -Name MSSQLSERVER -ErrorAction Stop"
        publish:
          # Optional: Publish the result and output for logging or further steps
          - mssql_stop_result: '${return_result}'
          - mssql_stop_output: '${script_stdout}'
        navigate:
          # If successful, proceed to stop Oracle on Linux
          - SUCCESS: stop_oracle_linux
          # If stopping MSSQL fails, go to the main flow failure handler
          - FAILURE: on_failure

    # Step 2: Stop Oracle Service on Linux Server
    - stop_oracle_linux:
        do:
          # Uses SSH to execute the command on the target Linux server
          io.cloudslang.base.ssh.ssh_command:
            # --- Inputs for Linux Server ---
            # Replace with actual Linux host IP or FQDN
            - host: 192.168.1.200
            # Replace with actual Linux username (e.g., oracle) with permissions to stop Oracle
            - username: oracle
            # Replace with actual Linux password - Using private key authentication is recommended for security
            - password:
                value: 'YourLinuxPassword!'
                sensitive: true
            # --- Command to stop Oracle ---
            # This is a simplified example using 'dbshut'.
            # The actual command depends heavily on your Oracle installation and environment setup.
            # It might require specifying $ORACLE_HOME, using sqlplus, or a custom script.
            # Example 1 (using dbshut, assuming ORACLE_HOME is set for the user): "dbshut $ORACLE_HOME"
            # Example 2 (using sqlplus): "lsnrctl stop; echo -e \"shutdown immediate;\\nexit;\" | sqlplus / as sysdba"
            # Choose the command appropriate for your environment.
            - command: "dbshut" # Replace with your actual Oracle stop command
            # Optional: Set command timeout if stopping takes time (value in milliseconds)
            # - timeout: '180000' # 3 minutes
        publish:
          # Optional: Publish the result and output
          - oracle_stop_result: '${return_result}'
          - oracle_stop_output: '${stdout}'
        navigate:
          # If successful, the entire flow succeeds
          - SUCCESS: SUCCESS
          # If stopping Oracle fails, go to the main flow failure handler
          - FAILURE: on_failure

  # Define the possible outcomes of the flow
  results:
    - SUCCESS # Reached if all steps complete successfully
    - FAILURE # Reached if any step fails and navigates to on_failure
