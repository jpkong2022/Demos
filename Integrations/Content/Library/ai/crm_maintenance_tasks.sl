namespace: ai
flow:
  name: crm_maintenance_tasks
  workflow:
    - delete_jptmp_crm_weblogic:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169
            - username: ec2-user
            - password:
                value: Automation.123
                sensitive: true
            - command: "rm -rf /jptmp"
            - pty: true # May be needed depending on server setup/permissions
        publish:
          - delete_output: '${return_result}'
          - delete_return_code: '${return_code}'
        # Navigate to the next step regardless of success or failure, as requested
        navigate:
          - SUCCESS: restart_crm_postgres
          - FAILURE: restart_crm_postgres # Continue even if delete fails

    - restart_crm_postgres:
        do:
          io.cloudslang.base.ssh.ssh_command:
            # Assuming the postgres server uses the same IP and credentials as weblogic, per the description.
            # If oracleserver1 has different credentials or IP, update here.
            - host: 172.31.28.169
            - username: ec2-user # Assuming same user has sudo rights for service restart
            - password:
                value: Automation.123
                sensitive: true
            # Assuming systemd is used and ec2-user has passwordless sudo rights
            - command: "sudo systemctl restart postgresql-17"
            - pty: true # Often required for sudo commands via SSH
        publish:
          - restart_output: '${return_result}'
          - restart_return_code: '${return_code}'
        # Navigate to SUCCESS state regardless of command outcome
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: SUCCESS # Go to SUCCESS even if restart command fails per requirement

  outputs:
    - delete_output: '${delete_output}'
    - delete_return_code: '${delete_return_code}'
    - restart_output: '${restart_output}'
    - restart_return_code: '${restart_return_code}'

  results:
    - SUCCESS # Only SUCCESS result defined as per the requirement to not check failures
    # - FAILURE # Typically would have a FAILURE result
