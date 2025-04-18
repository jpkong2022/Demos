namespace: ai

flow:
  name: stop_app4_and_disconnect_network
  inputs:
    # Credentials for Windows Servers (IIS & MSSQL)
    # Assuming SSH is enabled on Windows for this example, or adjust operation if using WinRM
    - win_host_user:
        required: true
    - win_host_password:
        required: true
        sensitive: true
    # Credentials for Cisco Router
    - router_user:
        required: true
    - router_password:
        required: true
        sensitive: true
    # Optional: Router port name if different from default assumption
    - router_interface:
        default: 'GigabitEthernet0/4' # Assuming interface name for port 4
        required: false
    - ssh_timeout:
        default: 90000 # Default timeout 90 seconds
        required: false
  workflow:
    # Step 1: Stop IIS Service on iisserver4
    - stop_iis_service:
        do:
          io.cloudslang.base.ssh.ssh_command: # Using SSH example, assumes SSH enabled on Windows. Use WinRM op if appropriate.
            - host: 10.20.20.1 # iisserver4 IP
            - username: '${win_host_user}'
            - password:
                value: '${win_host_password}'
                sensitive: true
            # Use appropriate command: 'net stop W3SVC' for CMD or 'Stop-Service W3SVC' via PowerShell executor
            - command: 'net stop W3SVC'
            - timeout: '${ssh_timeout}'
        publish:
          - iis_stop_result: '${return_result}'
          - iis_stop_code: '${return_code}'
        navigate:
          - SUCCESS: stop_mssql_service # Proceed even if one fails, or change logic to fail fast
          - FAILURE: stop_mssql_service # Decide if failure here should stop the whole flow or continue

    # Step 2: Stop MSSQL Service on omssqlserver3
    - stop_mssql_service:
        do:
          io.cloudslang.base.ssh.ssh_command: # Using SSH example, assumes SSH enabled on Windows. Use WinRM op if appropriate.
            - host: 10.20.22.2 # omssqlserver3 IP
            - username: '${win_host_user}'
            - password:
                value: '${win_host_password}'
                sensitive: true
            # Use appropriate command: 'net stop MSSQLSERVER' (or specific instance name)
            - command: 'net stop MSSQLSERVER' # Adjust if SQL instance name is different
            - timeout: '${ssh_timeout}'
        publish:
          - mssql_stop_result: '${return_result}'
          - mssql_stop_code: '${return_code}'
        navigate:
          - SUCCESS: shutdown_router_port
          - FAILURE: shutdown_router_port # Decide if failure here should stop the whole flow or continue

    # Step 3: Shutdown Router Port on router4
    - shutdown_router_port:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: 10.10.1.40 # router4 IP
            - port: 22 # Default SSH port
            - username: '${router_user}'
            - password:
                value: '${router_password}'
                sensitive: true
            # Commands to enter config mode, shutdown interface, and exit config mode
            - command: "configure terminal\ninterface ${router_interface}\nshutdown\nend"
            - pty: true # Often needed for Cisco config mode
            - timeout: '${ssh_timeout}'
        publish:
          - router_shutdown_output: '${return_result}'
          - router_shutdown_code: '${return_code}'
        navigate:
          # Determine overall success based on critical steps (e.g., router port shutdown)
          - SUCCESS: SUCCESS # Assuming router shutdown is the critical part for "disconnect"
          - FAILURE: on_failure

  results:
    - SUCCESS
    - FAILURE
