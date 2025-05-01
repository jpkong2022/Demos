namespace: ai
flow:
  name: run_uname_on_crm_weblogic
  workflow:
    - execute_uname_on_weblogic:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 172.31.28.169          # CRM WebLogic Server IP
            - username: ec2-user           # CRM WebLogic Server Username
            - password:
                value: 'Automation.123'    # CRM WebLogic Server Password
                sensitive: true
            - command: uname               # Command to execute
        publish:
          - uname_output: '${return_result}' # Publish the command output
          - return_code: '${return_code}'     # Publish the return code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  outputs:
    - uname_result: '${uname_output}' # Optional: Explicitly define flow output
    - execution_code: '${return_code}' # Optional: Explicitly define flow output
  results:
    - SUCCESS
    - FAILURE
