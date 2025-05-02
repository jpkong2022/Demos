namespace: ai
flow:
  name: set_max_locks_and_restart_aos_db
  workflow:
    - modify_postgres_config:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86  # AOS Postgres server IP
            - port: '5985'
            - protocol: http
            - username: administrator # AOS Postgres server username
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # AOS Postgres server password
                sensitive: true
            - auth_type: basic
            - script: |
                $configFile = "C:\Program Files\PostgreSQL\12\data\postgresql.conf" # Adjust path if necessary based on actual installation
                $parameter = 'max_locks_per_transaction'
                $newValue = 20
                $configLine = "$parameter = $newValue"
                $pattern = "^(#?)\s*$parameter\s*=.*" # Matches the line, commented or not

                if (Test-Path $configFile) {
                    $content = Get-Content $configFile
                    $found = $false
                    $newContent = @()
                    foreach ($line in $content) {
                        if ($line -match $pattern) {
                            $newContent += $configLine
                            $found = $true
                            Write-Host "Updated existing line: $configLine"
                        } else {
                            $newContent += $line
                        }
                    }
                    if (-not $found) {
                        $newContent += $configLine # Add the line if it wasn't found
                         Write-Host "Added new line: $configLine"
                    }
                    # Write the modified content back to the file
                    Set-Content -Path $configFile -Value $newContent -Force
                    Write-Host "Configuration updated successfully in $configFile."
                } else {
                    Write-Error "Configuration file not found at $configFile"
                    exit 1 # Exit with error code if file not found
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - config_update_result: '${return_result}'
          - config_update_stdout: '${stdout}'
          - config_update_stderr: '${stderr}'
        navigate:
          - SUCCESS: restart_postgres_service
          - FAILURE: on_failure
    - restart_postgres_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86 # AOS Postgres server IP
            - port: '5985'
            - protocol: http
            - username: administrator # AOS Postgres server username
            - password:
                value: '*9SG4-YBv&ANu%F?5%BlQszZ=ZX703nV' # AOS Postgres server password
                sensitive: true
            - auth_type: basic
            - script: "Restart-Service -Name 'postgresql-x64-12'" # AOS Postgres service name
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - service_restart_result: '${return_result}'
          - service_restart_stdout: '${stdout}'
          - service_restart_stderr: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - config_update_stdout: '${config_update_stdout}'
    - config_update_stderr: '${config_update_stderr}'
    - service_restart_stdout: '${service_restart_stdout}'
    - service_restart_stderr: '${service_restart_stderr}'
  results:
    - SUCCESS
    - FAILURE
