namespace: ai
flow:
  name: kill_chrome_on_mydesktop1
  workflow:
    - kill_chrome_process:
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
            - script: "taskkill /F /IM chrome.exe /T"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - kill_result: '${return_result}'
          - kill_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - kill_result: '${kill_result}'
    - kill_error: '${kill_error}'
  results:
    - SUCCESS
    - FAILURE
