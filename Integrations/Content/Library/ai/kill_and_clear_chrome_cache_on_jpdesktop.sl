namespace: ai
flow:
  name: kill_and_clear_chrome_cache_on_jpdesktop
  workflow:
    - kill_chrome_process:
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
            - script: "Stop-Process -Name 'chrome' -Force -ErrorAction SilentlyContinue"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: clear_chrome_cache
          - FAILURE: on_failure
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
                $userProfile = $env:USERPROFILE
                $chromeCachePath = Join-Path -Path $userProfile -ChildPath "AppData\Local\Google\Chrome\User Data\Default\Cache"
                if (Test-Path $chromeCachePath) {
                    Write-Host "Removing Chrome cache from $chromeCachePath"
                    Remove-Item -Path "$chromeCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    Write-Host "Chrome cache path not found."
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
