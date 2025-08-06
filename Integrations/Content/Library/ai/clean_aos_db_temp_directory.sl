namespace: ai
flow:
  name: clean_aos_db_temp_directory
  workflow:
    - check_temp_directory:
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
            - script: "if ((Get-ChildItem -Path C:\\Windows\\Temp -ErrorAction SilentlyContinue).Count -eq 0) { Write-Host 'EMPTY' } else { Write-Host 'NOT_EMPTY' }"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - directory_status: '${return_result}'
        navigate:
          - SUCCESS: decide_next_step
          - FAILURE: on_failure
    - decide_next_step:
        do:
          io.cloudslang.base.utils.equals:
            - first_string: '${directory_status.strip()}'
            - second_string: 'NOT_EMPTY'
        navigate:
          - SUCCESS: delete_temp_contents
          - FAILURE: SUCCESS
    - delete_temp_contents:
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
            - script: "Remove-Item -Path C:\\Windows\\Temp\\* -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'Temp directory contents deleted.'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
