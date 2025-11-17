namespace: ai
flow:
  name: kill_and_clear_chrome_cache
  workflow:
    - kill_chrome_process:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
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
            - username: administrator
            - password:
                value: "${get_sp('aosdb_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: |
                $userProfile = $env:USERPROFILE
                $cachePaths = @(
                    Join-Path -Path $userProfile -ChildPath 'AppData\Local\Google\Chrome\User Data\Default\Cache',
                    Join-Path -Path $userProfile -ChildPath 'AppData\Local\Google\Chrome\User Data\Default\Code Cache',
                    Join-Path -Path $userProfile -ChildPath 'AppData\Local\Google\Chrome\User Data\Default\GPUCache'
                )
                foreach ($path in $cachePaths) {
                    if (Test-Path $path) {
                        Remove-Item -Path $path -Recurse -Force
                        Write-Host "Successfully removed $path"
                    } else {
                        Write-Host "Path not found, skipping: $path"
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
