namespace: ai

imports:
  ssh: io.cloudslang.base.ssh

flow:
  name: manage_linux_services

  inputs:
    - target_host:
        required: true
        description: The hostname or IP address of the target Linux machine.
    - ssh_username:
        required: true
        description: The username for SSH connection.
    - ssh_password:
        required: true
        sensitive: true
        description: The password for SSH connection.
    - oracle_env_script:
        required: false
        description: Optional path to a script to source Oracle environment variables (e.g., /home/oracle/.bash_profile).
        default: ""
    - mysql_service_name:
        required: false
        description: The name of the MySQL service (e.g., mysqld, mysql).
        default: "mysqld" # Common default for systemd

  workflow:
    - cleanup_tmp_dir:
        do:
          ssh.ssh_command:
            - host: ${target_host}
            - username: ${ssh_username}
            - password: ${ssh_password}
            - command: "echo 'Cleaning /tmp directory...'; rm -rf /tmp/*; echo '/tmp cleaned.'"
            - timeout: "60000" # 60 seconds timeout
        navigate:
          - SUCCESS: check_oracle_running
          - FAILURE: on_failure

    - check_oracle_running:
        do:
          ssh.ssh_command:
            - host: ${target_host}
            - username: ${ssh_username}
            - password: ${ssh_password}
            # Check for the Oracle PMON process. Exit code 0 means found, non-zero means not found.
            # Source environment if script provided. Handle potential errors gracefully.
            - command: >
                ${oracle_env_script if oracle_env_script else ':'};
                echo 'Checking for Oracle PMON process...';
                ps -ef | grep '[p]mon_.*$' > /dev/null 2>&1;
                echo "Oracle check command exit code: $?"
        publish:
          - oracle_check_exit_code: ${return_code} # Capture the exit code of the ps command
        navigate:
          - SUCCESS: decide_next_action
          - FAILURE: on_failure # Treat SSH failure as overall failure

    - decide_next_action:
        decision:
          # If exit code is 0, pmon process was found (Oracle is running)
          - oracle_is_running: ${oracle_check_exit_code == '0'}
          # Otherwise, Oracle is not running
          - oracle_is_not_running: ${oracle_check_exit_code != '0'}

    - shutdown_oracle:
        # This step runs only if oracle_is_running is true
        match:
         - oracle_is_running
        do:
          ssh.ssh_command:
            - host: ${target_host}
            - username: ${ssh_username}
            - password: ${ssh_password}
            # IMPORTANT: Assumes the ssh_username has permissions and environment setup
            # to run sqlplus and shutdown Oracle. Sourcing the env script might be crucial.
            # This is a basic example; real shutdown might need more complex logic.
            - command: >
                ${oracle_env_script if oracle_env_script else ':'};
                echo "Oracle appears to be running. Attempting shutdown...";
                sqlplus / as sysdba <<< "shutdown immediate;";
                echo "Oracle shutdown command executed. Check Oracle logs for status."
            - timeout: "180000" # 3 minutes timeout for shutdown
        publish:
           - action_result: "Attempted Oracle Shutdown"
        navigate:
          - SUCCESS: SUCCESS # Successfully attempted shutdown
          - FAILURE: on_failure # Failed to execute shutdown command

    - start_mysql:
        # This step runs only if oracle_is_not_running is true
        match:
          - oracle_is_not_running
        do:
          ssh.ssh_command:
            - host: ${target_host}
            - username: ${ssh_username}
            - password: ${ssh_password}
            # Assumes ssh_username has sudo rights without password for systemctl/service
            # Tries systemd first, then init.d as fallback.
            - command: >
                echo "Oracle appears not to be running. Attempting to start MySQL (${mysql_service_name})...";
                (sudo systemctl start ${mysql_service_name} && echo "MySQL started via systemctl.") || \
                (sudo service ${mysql_service_name} start && echo "MySQL started via service.") || \
                (echo "Failed to start MySQL using systemctl or service. Check service name and permissions." && exit 1)
            - timeout: "120000" # 2 minutes timeout for startup
        publish:
           - action_result: "Attempted MySQL Start"
        navigate:
          - SUCCESS: SUCCESS # Successfully attempted start
          - FAILURE: on_failure # Failed to execute start command or service failed

  outputs:
    - final_action_result: ${action_result} # Reports which action (shutdown or start) was attempted

  results:
    - SUCCESS
    - FAILURE
