namespace: ai
flow:
  name: clear_chrome_cache_for_jp_on_mydesktop1
  workflow:
    - clear_chrome_cache:
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
                # Script to clear Chrome cache for user 'jp'
                $userName = "jp"
                $cachePath = "C:\Users\$userName\AppData\Local\Google\Chrome\User Data\Default\Cache"

                # Ensure Chrome is not running to avoid file lock issues
                Write-Host "Attempting to stop Chrome processes..."
                Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force

                # Check if the cache directory exists
                if (Test-Path $cachePath) {
                    Write-Host "Cache directory found at $cachePath. Clearing contents..."
                    # Get all child items (files and folders) and remove them
                    Get-ChildItem -Path $cachePath -Recurse | Remove-Item -Recurse -Force
                    Write-Host "Chrome cache for user '$userName' has been cleared successfully."
                } else {
                    Write-Error "Error: Chrome cache path for user '$userName' not found at $cachePath."
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
