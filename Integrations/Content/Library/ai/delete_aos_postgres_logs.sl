namespace: ai
flow:
  name: delete_aos_postgres_logs
  workflow:
    - delete_log_files:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('admin_password')}"
                sensitive: true
            - auth_type: basic
            - script: |
                $logDir = "C:\Program Files\PostgreSQL\12\data\log"
                if (Test-Path $logDir) {
                    Write-Host "Log directory found at $logDir. Deleting .log files..."
                    # Get a list of files to be deleted for reporting
                    $filesToDelete = Get-ChildItem -Path $logDir -Filter "*.log" -Recurse | ForEach-Object { $_.FullName }
                    if ($filesToDelete) {
                        Write-Host "Following files will be deleted:"
                        $filesToDelete | Write-Host
                        # Perform the deletion
                        Remove-Item -Path "$logDir\*.log" -Force -Recurse
                        Write-Host "Log files have been successfully deleted."
                    } else {
                        Write-Host "No .log files found to delete in $logDir."
                    }
                } else {
                    # The default log directory for many installations is pg_log
                    $logDirAlt = "C:\Program Files\PostgreSQL\12\data\pg_log"
                    if (Test-Path $logDirAlt) {
                        Write-Host "Log directory found at $logDirAlt. Deleting .log files..."
                        $filesToDelete = Get-ChildItem -Path $logDirAlt -Filter "*.log" -Recurse | ForEach-Object { $_.FullName }
                        if ($filesToDelete) {
                            Write-Host "Following files will be deleted:"
                            $filesToDelete | Write-Host
                            Remove-Item -Path "$logDirAlt\*.log" -Force -Recurse
                            Write-Host "Log files have been successfully deleted."
                        } else {
                            Write-Host "No .log files found to delete in $logDirAlt."
                        }
                    } else {
                      Write-Error "PostgreSQL log directory not found at the standard locations."
                      exit 1
                    }
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - delete_result: '${return_result}'
          - delete_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - delete_result: '${delete_result}'
    - delete_error: '${delete_error}'
  results:
    - SUCCESS
    - FAILURE
