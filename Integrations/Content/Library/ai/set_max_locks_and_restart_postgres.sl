namespace: ai
flow:
  name: set_max_locks_and_restart_postgres
  inputs:
    - host:
        required: true
        description: Hostname or IP address of the PostgreSQL server.
    - port:
        default: 22
        required: false
        description: SSH port for the PostgreSQL server.
    - username:
        required: true
        description: SSH username to connect to the PostgreSQL server.
    - password:
        required: true
        sensitive: true
        description: SSH password for the specified username.
    - postgres_conf_path:
        required: true
        description: Full path to the postgresql.conf file on the server (e.g., /var/lib/pgsql/data/postgresql.conf or /etc/postgresql/14/main/postgresql.conf).
    - postgres_service_name:
        required: true
        description: The name of the PostgreSQL service for restarting (e.g., postgresql, postgresql-14).
    - timeout:
        default: 90000 # Default timeout 90 seconds
        required: false
        description: SSH command timeout in milliseconds.
    # Note: This flow assumes the provided user has sudo privileges without a password prompt
    # or you are connecting as a user (like root or postgres) that can modify the file and restart the service directly.
    # Handling sudo passwords within the script is complex and less secure.

  workflow:
    - modify_postgres_config:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${host}'
            - port: '${port}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            # This command attempts to find the max_locks_per_transaction line (commented or not)
            # and replace it with the new value. It assumes the setting exists.
            # If the line does not exist at all, this command will not add it.
            # Using sudo assuming the user needs elevated privileges to edit the file.
            - command: "sudo sed -i -E 's/^[# ]*max_locks_per_transaction[[:space:]]*=[[:space:]]*.*/max_locks_per_transaction = 1024/' \"${postgres_conf_path}\""
            - pty: false # Usually false for non-interactive commands
            - timeout: '${timeout}'
        publish:
          - modify_return_code: '${return_code}'
          - modify_result: '${return_result}'
          - modify_exception: '${exception}'
        navigate:
          - SUCCESS: restart_postgres_service # Only restart if config change succeeded
          - FAILURE: on_failure

    - restart_postgres_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${host}'
            - port: '${port}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            # Using sudo assuming the user needs elevated privileges to restart the service.
            # Using systemctl as it's common, adjust if using 'service' or 'pg_ctl'.
            - command: "sudo systemctl restart ${postgres_service_name}"
            - pty: false
            - timeout: '${timeout}'
        publish:
          - restart_return_code: '${return_code}'
          - restart_result: '${return_result}'
          - restart_exception: '${exception}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - modify_return_code: '${modify_return_code}'
    - modify_result: '${modify_result}'
    - modify_exception: '${modify_exception}'
    - restart_return_code: '${restart_return_code}'
    - restart_result: '${restart_result}'
    - restart_exception: '${restart_exception}'

  results:
    - SUCCESS
    - FAILURE
