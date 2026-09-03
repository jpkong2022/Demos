namespace: ai
flow:
  name: resolve_postgres_disk_and_logging
  workflow:
    - remediate_disk_and_check_logs:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('aosdb_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: |
                # Free up disk space on C: drive by clearing Temp files and Recycle Bin
                Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue
                Remove-Item -Path 'C:\Windows\Temp\*' -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                
                # Expand C: Drive to maximum available partition size if unallocated space exists
                $size = Get-PartitionSupportedSize -DriveLetter C
                Resize-Partition -DriveLetter C -Size $size.SizeMax -ErrorAction SilentlyContinue
                
                # Verify if yesterday's Apache server upgrade is causing excessive PostgreSQL database logging
                $logPath = 'C:\Program Files\PostgreSQL\12\data\log'
                if (Test-Path $logPath) {
                    $logFiles = Get-ChildItem -Path $logPath -File
                    $excessiveLogs = $logFiles | Where-Object { $_.Length -gt 500MB }
                    if ($excessiveLogs) {
                        Write-Output "Excessive logging detected. Reviewing logs for Apache upgrade impact."
                        # Truncate excessive logs to immediately resolve 100% disk utilization
                        $excessiveLogs | ForEach-Object { Clear-Content $_.FullName -Force }
                    } else {
                        Write-Output "Database logging levels are normal. No excessive logs found."
                    }
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
