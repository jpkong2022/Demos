namespace: ai
flow:
  name: cleanup_tmp_directories
  workflow:
    - cleanup_crm_db_tmp:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
            - command: "rm -rf /tmp/*"
        publish:
          - crm_cleanup_result: '${return_result}'
          - crm_cleanup_error: '${stderr}'
        navigate:
          - SUCCESS: cleanup_aos_db_tmp
          - FAILURE: on_failure
    - cleanup_aos_db_tmp:
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
            - script: "if (Test-Path $env:TEMP) { Remove-Item -Path ($env:TEMP + '\\*') -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'AOS DB temp directory cleanup command executed.' }"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - aos_cleanup_result: '${return_result}'
          - aos_cleanup_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - crm_cleanup_result: '${crm_cleanup_result}'
    - crm_cleanup_error: '${crm_cleanup_error}'
    - aos_cleanup_result: '${aos_cleanup_result}'
    - aos_cleanup_error: '${aos_cleanup_error}'
  results:
    - SUCCESS
    - FAILURE
