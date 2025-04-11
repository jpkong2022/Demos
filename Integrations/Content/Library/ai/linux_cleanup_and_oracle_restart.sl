namespace: ai
flow:
  name: linux_cleanup_and_oracle_restart
  inputs:
    - host:
        required: true
    - username:
        required: true
    - password:
        required: true
        sensitive: true
    - oracle_service_name:
        default: 'oracle' # Common default, adjust if needed (e.g., oracledb, dbora)
        required: false
    - use_sudo:
        default: true # Assume sudo is needed for cleanup and restart
        required: false
    - private_key_file:
        required: false # Alternative to password
    - ssh_port:
        default: '22'
        required: false
    - connection_timeout:
        default: '90000' # milliseconds
        required: false
    - execution_timeout:
        default: '90000' # milliseconds
        required: false
  workflow:
    - cleanup_tmp_directory:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${host}'
            - port: '${ssh_port}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - private_key_file: '${private_key_file}' # Will be ignored if password is provided
            - command: "rm -rf /tmp/*"
            - use_sudo: '${use_sudo}'
            - pty: true # Often needed for sudo
            - connection_timeout: '${connection_timeout}'
            - execution_timeout: '${execution_timeout}'
        publish:
          - cleanup_output: '${return_result}'
          - cleanup_exit_code: '${return_code}'
        navigate:
          - SUCCESS: restart_oracle_server
          - FAILURE: on_failure # Go to implicit failure handler

    - restart_oracle_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${host}'
            - port: '${ssh_port}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - private_key_file: '${private_key_file}'
            # Assuming systemd is used. Adjust if using 'service' or other init system
            - command: "systemctl restart ${oracle_service_name}"
            - use_sudo: '${use_sudo}'
            - pty: true # Often needed for sudo and service restarts
            - connection_timeout: '${connection_timeout}'
            - execution_timeout: '${execution_timeout}'
        publish:
          - restart_output: '${return_result}'
          - restart_exit_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS # End successfully
          - FAILURE: on_failure # Go to implicit failure handler

  outputs:
    - cleanup_output: '${cleanup_output}'
    - cleanup_exit_code: '${cleanup_exit_code}'
    - restart_output: '${restart_output}'
    - restart_exit_code: '${restart_exit_code}'

  results:
    - SUCCESS
    - FAILURE
