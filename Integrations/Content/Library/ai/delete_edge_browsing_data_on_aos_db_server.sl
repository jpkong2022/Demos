namespace: ai
flow:
  name: delete_edge_browsing_data_on_aos_db_server
  workflow:
    - delete_edge_data:
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
                $edgeProfilePath = "C:\Users\administrator\AppData\Local\Microsoft\Edge\User Data"
                if (Test-Path $edgeProfilePath) {
                    Write-Host "Microsoft Edge user data directory found at $edgeProfilePath. Attempting to delete..."
                    Remove-Item -Path $edgeProfilePath -Recurse -Force
                    if (-not (Test-Path $edgeProfilePath)) {
                        Write-Host "Successfully deleted Edge browsing data."
                    } else {
                        Write-Error "Failed to delete the Edge browsing data directory."
                        exit 1
                    }
                } else {
                    Write-Host "Microsoft Edge user data directory not found at $edgeProfilePath. Nothing to do."
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - script_output: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
