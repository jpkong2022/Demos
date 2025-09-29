namespace: ai
flow:
  name: clear_edge_cache_jpdesktop
  workflow:
    - clear_edge_cache_for_user_jp:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - username: administrator
            - password:
                value: "${get_sp('aosdb_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: |
                $edgeCachePath = "C:\Users\jp\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
                if (Test-Path $edgeCachePath) {
                    Remove-Item -Path $edgeCachePath -Recurse -Force
                    Write-Host "Edge cache for user jp cleared successfully."
                } else {
                    Write-Host "Edge cache path for user jp not found."
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
