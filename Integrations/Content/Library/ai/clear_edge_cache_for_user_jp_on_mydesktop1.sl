namespace: ai
flow:
  name: clear_edge_cache_for_user_jp_on_mydesktop1
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
                $userProfile = "C:\Users\jp"
                $edgeCachePath = "$userProfile\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
                if (Test-Path $edgeCachePath) {
                    Write-Host "Found Edge cache for user jp at $edgeCachePath. Clearing cache..."
                    Remove-Item -Path "$edgeCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "Edge cache cleared successfully for user jp."
                } else {
                    Write-Host "Edge cache path for user jp not found. No action taken."
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - clear_cache_output: '${return_result}'
          - clear_cache_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - clear_cache_output: '${clear_cache_output}'
    - clear_cache_error: '${clear_cache_error}'
  results:
    - SUCCESS
    - FAILURE
