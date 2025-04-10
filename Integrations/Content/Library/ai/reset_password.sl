namespace: ai
flow:
  name: reset_password
  inputs:
    # --- Office 365 / Azure AD Inputs ---
    - user_principal_name: # The UserPrincipalName (email address) of the user
        required: true
    - new_password: # The new password to set for the user
        required: true
        sensitive: true
    - force_change_password_next_sign_in: # Boolean (true/false) - Whether the user must change password on next login
        default: 'true'
        required: false
    - client_id: # Azure AD App Registration Client ID with permissions (e.g., User.ReadWrite.All)
        required: true
    - tenant_id: # Your Azure AD Tenant ID
        required: true
    - client_secret: # Client Secret for the Azure AD App Registration
        required: true
        sensitive: true

    # --- PowerShell Execution Host Inputs ---
    - ps_host: # IP address or hostname of the Windows machine where PowerShell script will run
        required: true
    - ps_username: # Username for connecting to the PowerShell host (WinRM)
        required: true
    - ps_password: # Password for connecting to the PowerShell host (WinRM)
        required: true
        sensitive: true
    - ps_authentication: # WinRM authentication type (e.g., basic, ntlm, kerberos)
        default: 'basic'
        required: false
    - ps_trust_all_roots: # Set to 'true' if using self-signed certs for WinRM HTTPS (use with caution)
        default: 'false'
        required: false
    - ps_port: # WinRM port (usually 5985 for HTTP, 5986 for HTTPS)
        default: '5986' # Defaulting to HTTPS
        required: false

  workflow:
    - reset_o365_password_via_ps:
        do:
          io.cloudslang.base.powershell.powershell_script:
            # --- Connection Details ---
            - host: ${ps_host}
            - port: ${ps_port}
            - username: ${ps_username}
            - password:
                value: ${ps_password}
                sensitive: true
            - authentication: ${ps_authentication}
            - trust_all_roots: ${ps_trust_all_roots}
            # Use default x509_hostname_verifier ('strict') unless needed

            # --- PowerShell Script ---
            # Prerequisites on ps_host:
            # 1. WinRM configured (Enable-PSRemoting -Force)
            # 2. Microsoft Graph PowerShell SDK installed (Install-Module Microsoft.Graph -Scope AllUsers -Force)
            # 3. Network connectivity to Microsoft Graph endpoints
            - script: |
                #Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users

                # Input Parameters from CloudSlang Flow Inputs
                $clientId = '${client_id}'
                $tenantId = '${tenant_id}'
                $clientSecret = '${client_secret}' # CloudSlang handles passing the sensitive value securely
                $upn = '${user_principal_name}'
                $newPass = '${new_password}'       # CloudSlang handles passing the sensitive value securely
                $forceChange = [System.Convert]::ToBoolean('${force_change_password_next_sign_in}') # Convert string 'true'/'false' to boolean

                try {
                    Write-Host "Attempting to connect to Microsoft Graph..."
                    # Convert the plain text secret to a SecureString (required by Connect-MgGraph credential)
                    $secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential ($clientId, $secureClientSecret)

                    # Connect using Client Credentials Flow (App Registration)
                    Connect-MgGraph -TenantId $tenantId -Credential $credential -AppId $clientId
                    Write-Host "Successfully connected to Microsoft Graph."

                    # Prepare the password profile object
                    $passwordProfile = @{
                        Password = $newPass
                        ForceChangePasswordNextSignIn = $forceChange
                    }

                    Write-Host "Attempting to reset password for user: $upn"
                    # Update the user's password profile
                    Update-MgUser -UserId $upn -PasswordProfile $passwordProfile

                    Write-Host "Password successfully reset for user: $upn"

                } catch {
                    $errorMessage = "Failed to reset password for user: $upn. Error: $($_.Exception.Message)"
                    Write-Error $errorMessage
                    # Exit with a non-zero code to signal failure to CloudSlang
                    exit 1
                } finally {
                    # Disconnect from Microsoft Graph session if connected
                    if (Get-MgContext -ErrorAction SilentlyContinue) {
                        Write-Host "Disconnecting from Microsoft Graph..."
                        Disconnect-MgGraph
                    }
                }
        publish:
          - ps_stdout: ${return_result}
          - ps_stderr: ${error_message}
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure # Navigate to failure handler step

    - on_failure:
        do:
          io.cloudslang.base.utils.do_nothing: [] # Placeholder for actual failure handling logic
        navigate:
          - SUCCESS: FAILURE # End flow with FAILURE result

  outputs:
    - result_message: ${ps_stdout}
    - error_details: ${ps_stderr}

  results:
    - SUCCESS # Password reset was successful according to PowerShell script (exit code 0)
    - FAILURE # Password reset failed (PowerShell script exited with non-zero code or other error)
