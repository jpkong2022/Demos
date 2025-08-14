namespace: ai
flow:
  name: delete_tmp_files_on_crm_db
  workflow:
    - delete_files_in_tmp:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - command: 'rm -rf /tmp/*'
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
        publish:
          - delete_result: '${return_result}'
          - stderr: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - delete_result: '${delete_result}'
    - stderr: '${stderr}'
  results:
    - SUCCESS
    - FAILURE
