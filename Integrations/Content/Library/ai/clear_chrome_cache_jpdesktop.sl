namespace: ai
flow:
  name: clear_chrome_cache_jpdesktop
  workflow:
    - clear_chrome_cache:
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
                $cachePath = "C:\Users\jp\AppData\Local\Google\Chrome\User Data\Default\Cache"
                if (Test-Path $cachePath) {
                    Write-Host "Chrome cache directory found at $cachePath. Clearing contents..."
                    try {
                        Remove-Item -Path "$cachePath\*" -Recurse -Force -ErrorAction Stop
                        Write-Host "Successfully cleared Chrome cache for user jp."
                    } catch {
                        Write-Error "Failed to clear Chrome cache. Error: $_"
                        exit 1
                    }
                } else {
                    Write-Host "Chrome cache directory for user jp not found at $cachePath. No action taken."
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - command_output: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - result: '${command_output}'
  results:
    - SUCCESS
    - FAILURE
