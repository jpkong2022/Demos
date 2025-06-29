namespace: ai
flow:
  name: clear_edge_cache_for_user_jp_on_mydesktop1
  workflow:
    - clear_edge_cache_step:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "get_sp('admin_password')"
                sensitive: true
            - auth_type: basic
            - script: |
                # Stop Microsoft Edge processes to release file locks
                Write-Host "Stopping Microsoft Edge processes..."
                Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force
                Start-Sleep -Seconds 3 # Give a moment for processes to terminate

                $user = 'jp'
                $cachePath = "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache"

                if (Test-Path $cachePath) {
                    Write-Host "Cache path found at $cachePath. Attempting to clear..."
                    Remove-Item -Path "$cachePath\*" -Recurse -Force
                    Write-Host "Edge cache cleared for user $user."
                } else {
                    Write-Error "Cache path not found for user $user at $cachePath."
                    exit 1
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
