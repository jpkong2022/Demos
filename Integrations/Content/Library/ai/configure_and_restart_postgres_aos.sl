namespace: ai
flow:
  name: configure_and_restart_postgres_aos
  workflow:
    - modify_postgres_config:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86          # AOS Postgres server IP
            - port: '5985'                 # Default WinRM HTTP port
            - protocol: http               # Assuming HTTP WinRM, change to https if configured
            - username: administrator      # AOS Postgres server username
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # AOS Postgres server password
                sensitive: true
            - auth_type: basic             # Or negotiate, ntlm depending on WinRM config
            - script: |
                # Adjust path if necessary. Assuming default install path for PostgreSQL 12
                $configFile = "C:\Program Files\PostgreSQL\12\data\postgresql.conf"
                $settingName = "max_locks_per_transaction"
                $newValue = "10"

                if (Test-Path $configFile) {
                    $content = Get-Content $configFile
                    $updatedContent = @()
                    $settingFound = $false

                    foreach ($line in $content) {
                        if ($line -match "^\s*#?\s*$($settingName)\s*=") {
                            $updatedContent += "$($settingName) = $($newValue)"
                            $settingFound = $true
                            Write-Host "Updated '$($settingName)' setting."
                        } else {
                            $updatedContent += $line
                        }
                    }

                    if (-not $settingFound) {
                         # Setting not found, add it at the end
                         Write-Host "Setting '$($settingName)' not found, adding it."
                         $updatedContent += "$($settingName) = $($newValue)"
                    }

                    # Use -Force to overwrite if file is read-only (might require admin rights)
                    # Use -Encoding Default or UTF8 as appropriate for your postgresql.conf encoding
                    try {
                        Set-Content -Path $configFile -Value $updatedContent -Encoding Default -Force
                        Write-Host "Configuration updated successfully in $configFile"
                    } catch {
                        Write-Error "Failed to write to $configFile. Error: $($_.Exception.Message)"
                        exit 1
                    }

                } else {
                    Write-Error "Configuration file not found at $configFile"
                    exit 1 # Exit with error code if file not found
                }
            - trust_all_roots: 'true'        # Use 'false' in production with proper certs
            - x_509_hostname_verifier: allow_all # Use 'strict' in production
        publish:
          - config_update_result: '${return_result}'
          - config_update_error: '${stderr}'
        navigate:
          - SUCCESS: restart_postgres_service
          - FAILURE: on_failure

    - restart_postgres_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86          # AOS Postgres server IP
            - port: '5985'
            - protocol: http
            - username: administrator      # AOS Postgres server username
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # AOS Postgres server password
                sensitive: true
            - auth_type: basic
            - script: "Restart-Service -Name 'postgresql-x64-12' -Force" # AOS Postgres service name
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - service_restart_result: '${return_result}'
          - service_restart_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - config_update_result: '${config_update_result}'
    - config_update_error: '${config_update_error}'
    - service_restart_result: '${service_restart_result}'
    - service_restart_error: '${service_restart_error}'

  results:
    - SUCCESS
    - FAILURE
