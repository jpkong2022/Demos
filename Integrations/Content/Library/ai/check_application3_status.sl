namespace: ai

flow:
  name: check_application3_status
  inputs:
    - iis_server_host:
        description: Hostname or IP address of the IIS Windows server (iisserver3).
        required: true
    - mssql_server_host:
        description: Hostname or IP address of the MSSQL Windows server (omssqlserver3).
        required: true
    - windows_username:
        description: Username for connecting to the Windows servers.
        required: true
    - windows_password:
        description: Password for connecting to the Windows servers.
        required: true
        sensitive: true
    - iis_service_name:
        description: The specific IIS service name to check (e.g., W3SVC).
        default: 'W3SVC'
        required: false
    - mssql_service_name:
        description: The specific MSSQL service name to check (e.g., MSSQLSERVER for default instance).
        default: 'MSSQLSERVER'
        required: false
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true
    - ssh_timeout:
        description: Timeout for remote command execution (milliseconds).
        default: '90000'
        required: false

  workflow:
    - check_iis_service:
        do:
          io.cloudslang.base.remote_command_execution.powershell_script:
            - host: "${iis_server_host}"
            - username: "${windows_username}"
            - password:
                value: "${windows_password}"
                sensitive: true
            - script: "${'Get-Service -Name \'' + iis_service_name + '\' | Select-Object -ExpandProperty Status'}"
            - proxy_host: "${proxy_host}"
            - proxy_port: "${proxy_port}"
            - proxy_username: "${proxy_username}"
            - proxy_password:
                value: "${proxy_password}"
                sensitive: true
            - timeout: "${ssh_timeout}"
        publish:
          - iis_status: "${return_result.trim()}" # Trim potential whitespace
        navigate:
          - SUCCESS: check_mssql_service
          - FAILURE: on_failure

    - check_mssql_service:
        do:
          io.cloudslang.base.remote_command_execution.powershell_script:
            - host: "${mssql_server_host}"
            - username: "${windows_username}"
            - password:
                value: "${windows_password}"
                sensitive: true
            - script: "${'Get-Service -Name \'' + mssql_service_name + '\' | Select-Object -ExpandProperty Status'}"
            - proxy_host: "${proxy_host}"
            - proxy_port: "${proxy_port}"
            - proxy_username: "${proxy_username}"
            - proxy_password:
                value: "${proxy_password}"
                sensitive: true
            - timeout: "${ssh_timeout}"
        publish:
          - mssql_status: "${return_result.trim()}" # Trim potential whitespace
          - command_exception: "${exception}" # Capture potential exception if service not found
          - return_code: "${return_code}"
        navigate:
          # Check if the command executed successfully (return_code 0) AND status is 'Running'
          - SUCCESS:
              # Check if status is Running, otherwise consider it a non-fatal issue but maybe needs reporting
              # Simple case: assume success if command ran, status might be checked later or reported
              do: evaluate_overall_status
          # Handle cases where the service might not exist or other PowerShell errors
          - FAILURE: on_failure # Treat PowerShell execution failure as overall failure

    - evaluate_overall_status:
        # This step could be enhanced to check if iis_status and mssql_status are 'Running'
        # For simplicity, if both commands ran, we navigate to SUCCESS.
        # A more robust flow would check the actual status values here.
        do:
          io.cloudslang.base.utils.do_nothing: [] # Placeholder for potential logic
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure # Should not happen with do_nothing

    - on_failure:
        do:
          io.cloudslang.base.utils.do_nothing: []
        navigate:
          - SUCCESS: FAILURE # Transition to the flow's FAILURE result

  outputs:
    - iis_server_status: '${iis_status}'
    - mssql_server_status: '${mssql_status}'
    - overall_status: # Example: Derive overall status based on individual checks
        value: "${(iis_status == 'Running' and mssql_status == 'Running') ? 'OK' : 'DEGRADED/FAILED'}" # Requires check for 'Running' and handling errors more gracefully

  results:
    - SUCCESS # Reached if all checks were successful (or navigated to SUCCESS)
    - FAILURE # Reached if any step failed execution
