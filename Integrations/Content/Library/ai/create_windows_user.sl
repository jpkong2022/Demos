namespace: ai
imports:
  ps: io.cloudslang.base.powershell
  utils: io.cloudslang.base.utils
flow:
  name: create_windows_user
  inputs:
    - host:
        description: The hostname or IP address of the target Windows machine.
        required: true
    - username:
        description: The administrative username to connect to the Windows machine (for WinRM).
        required: true
    - password:
        description: The password for the administrative username.
        required: true
        sensitive: true
    - new_user_name:
        description: The username for the new Windows user to be created.
        required: true
    - new_user_password:
        description: The password for the new Windows user.
        required: true
        sensitive: true
    - description:
        description: Optional description for the new user account.
        required: false
        default: ""
    - winrm_timeout:
        description: Optional timeout in seconds for the WinRM connection.
        required: false
        default: "60"
  workflow:
    - check_inputs:
        do:
          utils.validate_string_input:
            - input_string: ${host}
            - input_name: "'host'"
          utils.validate_string_input:
            - input_string: ${username}
            - input_name: "'username'"
          utils.validate_string_input:
            - input_string: ${password}
            - input_name: "'password'"
          utils.validate_string_input:
            - input_string: ${new_user_name}
            - input_name: "'new_user_name'"
          utils.validate_string_input:
            - input_string: ${new_user_password}
            - input_name: "'new_user_password'"
        navigate:
          - SUCCESS: create_user
          - FAILURE: on_failure
    - create_user:
        do:
          ps.powershell_script:
            - host: ${host}
            - username: ${username}
            - password:
                value: ${password}
                sensitive: true
            # Use New-LocalUser for modern PowerShell, fallback to net user if needed
            # Ensure quotes handle spaces in username/password/description
            - script: |
                $newUser = "${new_user_name}"
                $newPassword = ConvertTo-SecureString "${new_user_password}" -AsPlainText -Force
                $desc = "${description}"
                try {
                    # Check if user already exists
                    $existingUser = Get-LocalUser -Name $newUser -ErrorAction SilentlyContinue
                    if ($existingUser) {
                        Write-Error "User '$newUser' already exists."
                        exit 1 # Indicate failure
                    }
                    # Create the user
                    $params = @{
                        Name = $newUser
                        Password = $newPassword
                        PasswordNeverExpires = $true # Default, change if needed
                        UserMayNotChangePassword = $false # Default, change if needed
                    }
                    if ($desc -ne "") {
                        $params.Add("Description", $desc)
                    }

                    New-LocalUser @params -ErrorAction Stop
                    Write-Host "User '$newUser' created successfully."
                    exit 0 # Indicate success

                } catch {
                    Write-Error "Failed to create user '$newUser'. Error: $($_.Exception.Message)"
                    exit 1 # Indicate failure
                }
            - timeout: ${winrm_timeout}
        publish:
          - return_code
          - return_result
          - exception
        navigate:
          - SUCCESS: ${on_success if return_code == '0' else on_failure} # Check exit code from script
          - FAILURE: on_failure # Operation level failure (e.g., connection)
  outputs:
    - result_message: ${return_result}
    - operation_return_code: ${return_code} # Exit code from the script itself
    - operation_exception: ${exception}
  results:
    - SUCCESS: ${return_code == '0'}
    - FAILURE