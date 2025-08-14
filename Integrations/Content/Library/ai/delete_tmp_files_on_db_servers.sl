namespace: ai
flow:
  name: delete_tmp_files_on_db_servers
  workflow:
    - delete_tmp_on_aos_db:
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
            - script: "Write-Host 'Clearing TEMP directory...'; Remove-Item -Path $env:TEMP\\* -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'TEMP directory cleared.'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - aos_db_cleanup_result: '${return_result}'
        navigate:
          - SUCCESS: delete_tmp_on_crm_db
          - FAILURE: on_failure
    - delete_tmp_on_crm_db:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
            - command: "sudo find /tmp -mindepth 1 -delete"
            - pty: true
        publish:
          - crm_db_cleanup_result: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - aos_db_cleanup_result: '${aos_db_cleanup_result}'
    - crm_db_cleanup_result: '${crm_db_cleanup_result}'
  results:
    - SUCCESS
    - FAILURE
