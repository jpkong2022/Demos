namespace: ai
flow:
  name: delete_tmp_files_on_crm_db
  workflow:
    - delete_tmp_files:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: 'Automation.123'
                sensitive: true
            - command: 'rm -rf /tmp/*'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
