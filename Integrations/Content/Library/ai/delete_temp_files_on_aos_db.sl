namespace: ai
flow:
  name: delete_temp_files_on_aos_db
  workflow:
    - delete_files_in_temp_directory:
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
                $tempDir = $env:TEMP
                if (Test-Path $tempDir) {
                    Write-Host "Clearing files and folders in $($tempDir)..."
                    Get-ChildItem -Path $tempDir -Recurse | Remove-Item -Force -Recurse
                    Write-Host "Temp directory cleared."
                } else {
                    Write-Host "Temp directory not found."
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - command_output: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
