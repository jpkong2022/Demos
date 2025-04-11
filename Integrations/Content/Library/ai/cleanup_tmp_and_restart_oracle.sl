namespace: ai
flow:
  name: cleanup_tmp_and_restart_oracle
  inputs:
    - host:
        required: true
    - port:
        default: '22'
        required: false
    - username:
        required: true
    - password:
        required: true
        sensitive: true
    - private_key_file:
        required: false
    - cleanup_command:
        default: 'rm -rf /tmp/*'
        required: false
    - restart_command:
        # Note: Adjust this command based on your specific Oracle environment
        # Examples: systemctl restart oracle-db, /u01/app/oracle/product/19c/dbhome_1/bin/dbshut && /u01/app/oracle/product/19c/dbhome_1/bin/dbstart
        default: 'sudo systemctl restart oracle-database' # Example for systemd, adjust as needed
        required: false
    - connection_timeout:
        default: '90000'
        required: false
    - execution_timeout:
        default: '90000'
        required: false
    - pty: # Set to true if sudo requires a password prompt (use with caution)
        default: 'false'
        required: false

  workflow:
    - cleanup_tmp_directory:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${host}'
            - port: '${port}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - private_key_file: '${private_key_file}'
            - command: '${cleanup_command}'
            - pty: '${pty}'
            - timeout: '${connection_timeout}'
            - execution_timeout: '${execution_timeout}'
        publish:
          - cleanup_stdout: '${return_result}'
          - cleanup_stderr: '${error_message}'
          - cleanup_return_code: '${return_code}'
        navigate:
          - SUCCESS: restart_oracle_server
          - FAILURE: on_failure

    - restart_oracle_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${host}'
            - port: '${port}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - private_key_file: '${private_key_file}'
            - command: '${restart_command}'
            - pty: '${pty}' # May be needed if restart_command uses sudo and prompts
            - timeout: '${connection_timeout}'
            - execution_timeout: '${execution_timeout}' # Restart might take longer
        publish:
          - restart_stdout: '${return_result}'
          - restart_stderr: '${error_message}'
          - restart_return_code: '${return_code}'
        navigate:
          # Check return code explicitly if needed, otherwise assume 0 is SUCCESS
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - cleanup_stdout: '${cleanup_stdout}'
    - cleanup_stderr: '${cleanup_stderr}'
    - cleanup_return_code: '${cleanup_return_code}'
    - restart_stdout: '${restart_stdout}'
    - restart_stderr: '${restart_stderr}'
    - restart_return_code: '${restart_return_code}'

  results:
    - SUCCESS
    - FAILURE
