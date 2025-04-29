namespace: ai
flow:
  name: stop_aos_application
  workflow:
    - stop_aos_service_on_apacheserver1:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.54.247                  # AOS Apache Server IP
            - port: '5985'                         # Default WinRM HTTP port
            - protocol: http
            - username: administrator              # AOS Apache Server Username
            - password:
                value: "31lGg&d%Dv-it.A8muSGzIH&ezg6Gz=8" # AOS Apache Server Password
                sensitive: true
            - auth_type: basic                     # Basic authentication often used
            - script: Stop-Service -Name "AOS"     # PowerShell command to stop the AOS service
            - trust_all_roots: 'true'              # Often needed for non-domain/self-signed certs
            - x_509_hostname_verifier: allow_all   # Often needed for non-domain/self-signed certs
        publish:
          - stop_result: '${return_result}'
          - return_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS                      # If script execution successful (may not mean service stopped if permissions issue etc.)
          - FAILURE: on_failure                   # If script execution fails (e.g., connection error, auth failure)

    # Optional: Add a step to verify the service is actually stopped
    - verify_aos_service_stopped:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.54.247
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "31lGg&d%Dv-it.A8muSGzIH&ezg6Gz=8"
                sensitive: true
            - auth_type: basic
            - script: '(Get-Service -Name "AOS").Status' # Get the status of the AOS service
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - service_status: '${return_result}'
        navigate:
          # Check if the status returned is 'Stopped'
          - IS_EQUAL:
              - '${return_result.strip()}' # Use strip() to remove potential whitespace/newlines
              - 'Stopped'
              - SUCCESS # If status is Stopped, flow is successful
          - FAILURE: on_failure # If status is not Stopped, consider it a failure

  outputs:
    - stop_command_output: '${stop_result}'
    - final_service_status: '${service_status}'
    - stop_command_return_code: '${return_code}'

  results:
    - SUCCESS
    - FAILURE
