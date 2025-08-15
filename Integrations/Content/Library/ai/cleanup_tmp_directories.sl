namespace: ai
flow:
  name: cleanup_tmp_directories
  workflow:
    - start_cleanup:
        fork:
          - cleanup_crm_db_tmp
          - cleanup_aos_db_tmp
    - cleanup_crm_db_tmp:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: "Automation.123"
                sensitive: true
            - command: "rm -rf /tmp/*"
        navigate:
          - SUCCESS: join_cleanup
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
            - script: "Remove-Item -Path \"C:\\Windows\\Temp\\*\" -Recurse -Force -ErrorAction SilentlyContinue"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: join_cleanup
          - FAILURE: on_failure
    - join_cleanup:
        join:
          - SUCCESS
          - FAILURE
  results:
    - SUCCESS
    - FAILURE
