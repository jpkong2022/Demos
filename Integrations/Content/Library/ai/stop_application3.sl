namespace: ai

flow:
  name: stop_application3
  inputs:
    - iis_host:
        default: "iisserver3" # Default based on application info
        required: true
    - iis_username:
        required: true
    - iis_password:
        required: true
        sensitive: true
    - mssql_host:
        default: "omssqlserver3" # Default based on application info
        required: true
    - mssql_username:
        required: true
    - mssql_password:
        required: true
        sensitive: true
    # Optional: Specify exact service names if known and defaults aren't sufficient
    - iis_service_name:
        default: "W3SVC" # Common service name for IIS World Wide Web Publishing
        required: false
    - mssql_service_name:
        # This often includes an instance name, e.g., MSSQL$SQLEXPRESS or MSSQLSERVER
        # User should provide the correct one if the default isn't right
        default: "MSSQLSERVER" # Default instance name, may need override
        required: false
    - win_protocol:
        default: "powershell" # Protocol for remote execution (WinRM)
        required: false
    - win_port: # Default WinRM ports (5985 http, 5986 https) - op might handle defaults
        required: false
    - command_timeout:
        default: '60000' # milliseconds
        required: false
  workflow:
    # Step 1: Stop IIS Service on iisserver3
    - stop_iis_service:
        do:
          # Assuming a generic remote command execution operation exists
          # Replace with specific windows service operation if available, e.g.,
          # io.cloudslang.windows.services.stop_service
          io.cloudslang.base.remote_command_execution.remote_command_executor:
            - host: ${iis_host}
            - port: ${win_port}
            - protocol: ${win_protocol}
            - username: ${iis_username}
            - password:
                value: ${iis_password}
                sensitive: true
            - command: "Stop-Service -Name ${iis_service_name} -Force" # Force stops dependent services too
            - timeout: ${command_timeout}
        publish:
          - iis_stop_result: '${return_result}'
          - iis_stop_return_code: '${return_code}'
          - iis_stop_stdout: '${stdout}'
          - iis_stop_stderr: '${stderr}'
        navigate:
          - SUCCESS: stop_mssql_service # Proceed to stop DB after IIS
          - FAILURE: on_failure # If IIS stop fails, report failure

    # Step 2: Stop MS SQL Service on omssqlserver3
    - stop_mssql_service:
        do:
          # Assuming a generic remote command execution operation exists
          # Replace with specific windows service operation if available
          io.cloudslang.base.remote_command_execution.remote_command_executor:
            - host: ${mssql_host}
            - port: ${win_port}
            - protocol: ${win_protocol}
            - username: ${mssql_username}
            - password:
                value: ${mssql_password}
                sensitive: true
            # Note: Stopping SQL Server might impact other apps. Ensure this is intended.
            - command: "Stop-Service -Name ${mssql_service_name} -Force"
            - timeout: ${command_timeout}
        publish:
          - mssql_stop_result: '${return_result}'
          - mssql_stop_return_code: '${return_code}'
          - mssql_stop_stdout: '${stdout}'
          - mssql_stop_stderr: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS # Both stopped successfully
          - FAILURE: on_failure # If MSSQL stop fails, report failure

    # Failure handling step
    - on_failure:
        do:
          io.cloudslang.base.utils.do_nothing: [] # Placeholder for potential error handling logic
        navigate:
          - SUCCESS: FAILURE # Transition flow to FAILURE result

  outputs:
    - iis_stop_result: '${iis_stop_result}'
    - iis_stop_return_code: '${iis_stop_return_code}'
    - iis_stop_stdout: '${iis_stop_stdout}'
    - iis_stop_stderr: '${iis_stop_stderr}'
    - mssql_stop_result: '${mssql_stop_result}'
    - mssql_stop_return_code: '${mssql_stop_return_code}'
    - mssql_stop_stdout: '${mssql_stop_stdout}'
    - mssql_stop_stderr: '${mssql_stop_stderr}'
    - final_outcome:
        value: "${'Application3 stopped successfully.' if return_code == '0' else 'Failed to stop Application3.'}"

  results:
    - SUCCESS: ${mssql_stop_return_code == '0'} # Success only if the last critical step (MSSQL stop) succeeded
    - FAILURE
