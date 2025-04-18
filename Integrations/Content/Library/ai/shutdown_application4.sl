namespace: ai
flow:
  name: shutdown_application4
  inputs:
    # --- Windows Server Inputs ---
    - iis_host:
        default: 10.20.20.1
        required: false
    - mssql_host:
        default: 10.20.22.2
        required: false
    - windows_username:
        required: true
    - windows_password:
        required: true
        sensitive: true
    # --- Router Inputs ---
    - router_host:
        default: 10.10.1.40
        required: false
    - router_port:
        default: 22
        required: false
    - router_username:
        required: true
    - router_password:
        required: true
        sensitive: true
    - router_interface_port: # The specific interface name connected to port 4, e.g., GigabitEthernet0/4
        default: 'GigabitEthernet0/4' # Assumption: Adjust if needed
        required: true
    - ssh_timeout:
        default: 90000 # Default timeout 90 seconds
        required: false

  workflow:
    # Step 1: Shutdown IIS Server (Assuming SSH is enabled on Windows)
    - shutdown_iis_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${iis_host}
            - port: 22 # Assuming standard SSH port
            - username: ${windows_username}
            - password:
                value: ${windows_password}
                sensitive: true
            - command: 'shutdown /s /f /t 0' # Force immediate shutdown
            - pty: false # Usually false for non-interactive commands on Windows SSH
            - timeout: ${ssh_timeout}
        publish:
          - iis_shutdown_result: '${return_result}'
          - iis_shutdown_code: '${return_code}'
        navigate:
          - SUCCESS: shutdown_mssql_server
          - FAILURE: on_failure

    # Step 2: Shutdown MSSQL Server (Assuming SSH is enabled on Windows)
    - shutdown_mssql_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${mssql_host}
            - port: 22 # Assuming standard SSH port
            - username: ${windows_username}
            - password:
                value: ${windows_password}
                sensitive: true
            - command: 'shutdown /s /f /t 0' # Force immediate shutdown
            - pty: false # Usually false for non-interactive commands on Windows SSH
            - timeout: ${ssh_timeout}
        publish:
          - mssql_shutdown_result: '${return_result}'
          - mssql_shutdown_code: '${return_code}'
        navigate:
          - SUCCESS: disconnect_router_port
          - FAILURE: on_failure

    # Step 3: Disconnect Router Port (Shutdown Interface)
    - disconnect_router_port:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${router_host}
            - port: ${router_port}
            - username: ${router_username}
            - password:
                value: ${router_password}
                sensitive: true
            - command: "configure terminal\ninterface ${router_interface_port}\nshutdown\nend\n" # Commands separated by newline
            - pty: true # Often needed for Cisco configuration mode
            - timeout: ${ssh_timeout}
        publish:
          - router_disconnect_result: '${return_result}'
          - router_disconnect_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - iis_shutdown_result: '${iis_shutdown_result}'
    - iis_shutdown_code: '${iis_shutdown_code}'
    - mssql_shutdown_result: '${mssql_shutdown_result}'
    - mssql_shutdown_code: '${mssql_shutdown_code}'
    - router_disconnect_result: '${router_disconnect_result}'
    - router_disconnect_code: '${router_disconnect_code}'

  results:
    - SUCCESS
    - FAILURE
