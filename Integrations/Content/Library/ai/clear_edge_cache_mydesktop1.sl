namespace: ai
flow:
  name: clear_edge_cache_mydesktop1
  workflow:
    - clear_edge_cache:
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
                $user = "jp"
                $edgeCachePath = "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
                
                if (Test-Path $edgeCachePath) {
                    try {
                        Write-Host "Attempting to clear Edge cache for user '$user' at: $edgeCachePath"
                        Remove-Item -Path "$edgeCachePath\*" -Recurse -Force -ErrorAction Stop
                        Write-Host "Successfully cleared contents of Edge cache directory for user '$user'."
                    } catch {
                        Write-Error "Failed to clear Edge cache for user '$user'. Error: $_"
                        exit 1
                    }
                } else {
                    Write-Host "Edge cache path for user '$user' not found. Nothing to do."
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - script_output: '${return_result}'
          - script_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - script_output: '${script_output}'
    - script_error: '${script_error}'
  results:
    - SUCCESS
    - FAILURE
