namespace: ai

flow:
  name: multi_system_stop_and_disable
  inputs:
    # Cisco Router Inputs
    - router_host:
        required: true
    - router_username:
        required: true
    - router_password:
        required: true
        sensitive: true
    - router_port:
        default: 22
        required: false
    - interface_name: # e.g., GigabitEthernet0/1
        required: true
    - router_timeout:
        default: 90000 # Default timeout 90 seconds
        required: false

    # Linux Application Server Inputs
    - linux_app_host:
        required: true
    - linux_app_username:
        required: true
    - linux_app_password:
        required: true
        sensitive: true
    - linux_app_port:
        default: 22
        required: false
    - weblogic_service_name: # Or path to stop script if not using systemd/service
        default: 'weblogic_managed_server' # Example service name
        required: false
    - linux_timeout:
        default: 60000 # Default timeout 60 seconds
        required: false

    # Windows Database Server Inputs
    - windows_db_host:
        required: true
    - windows_db_username: # Ensure SSH server is running on Windows if using SSH
        required: true
    - windows_db_password:
        required: true
        sensitive: true
    - windows_db_port:
        default: 22 # Assuming SSH port for consistency, adjust if using WinRM etc.
        required: false
    - mssql_service_name:
        default: 'MSSQLSERVER' # Default instance service name
        required: false
    - windows_timeout:
        default: 60000 # Default timeout 60 seconds
        required: false

  workflow:
    - disable_cisco_port:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${router_host}'
            - port: '${router_port}'
            - username: '${router_username}'
            - password:
                value: '${router_password}'
                sensitive: true
            # Multi-line command for Cisco configuration
            - command: >
                configure terminal
                interface ${interface_name}
                shutdown
                end
                exit
            - pty: true # Often needed for Cisco configure mode
            - timeout: '${router_timeout}'
        publish:
          - router_disable_output: '${return_result}'
          - router_disable_return_code: '${return_code}'
        navigate:
          - SUCCESS: stop_weblogic_linux
          - FAILURE: on_failure

    - stop_weblogic_linux:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${linux_app_host}'
            - port: '${linux_app_port}'
            - username: '${linux_app_username}'
            - password:
                value: '${linux_app_password}'
                sensitive: true
            # Adjust command based on Linux distro and WebLogic setup
            # Example assumes systemd, might need 'sudo' depending on user/config
            - command: "sudo systemctl stop ${weblogic_service_name}"
            - pty: false # Usually not needed for simple service stop
            - timeout: '${linux_timeout}'
        publish:
          - weblogic_stop_output: '${return_result}'
          - weblogic_stop_return_code: '${return_code}'
        navigate:
          - SUCCESS: stop_mssql_windows
          - FAILURE: on_failure # Consider rollback or notification steps

    - stop_mssql_windows:
        do:
          # Assumes SSH is enabled on the Windows Server.
          # If using WinRM, use io.cloudslang.base.remote_command_executor.win_rm_command_executor instead
          io.cloudslang.base.ssh.ssh_command:
            - host: '${windows_db_host}'
            - port: '${windows_db_port}'
            - username: '${windows_db_username}'
            - password:
                value: '${windows_db_password}'
                sensitive: true
            # Command to stop MSSQL Service
            - command: "net stop ${mssql_service_name}"
            - pty: false
            - timeout: '${windows_timeout}'
        publish:
          - mssql_stop_output: '${return_result}'
          - mssql_stop_return_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure # Consider rollback or notification steps

  outputs:
    - router_disable_output: '${router_disable_output}'
    - router_disable_return_code: '${router_disable_return_code}'
    - weblogic_stop_output: '${weblogic_stop_output}'
    - weblogic_stop_return_code: '${weblogic_stop_return_code}'
    - mssql_stop_output: '${mssql_stop_output}'
    - mssql_stop_return_code: '${mssql_stop_return_code}'

  results:
    - SUCCESS
    - FAILURE
