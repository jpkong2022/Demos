namespace: ai
flow:
  name: shutdown_application2_and_disconnect
  inputs:
    # --- WebLogic Server Inputs ---
    - weblogic_host:
        required: true
        description: Hostname or IP address of the WebLogic Linux server (weblogicserver2).
    - weblogic_ssh_port:
        default: 22
        required: false
    - weblogic_ssh_user:
        required: true
        description: SSH username for weblogicserver2.
    - weblogic_ssh_password:
        required: true
        sensitive: true
        description: SSH password for weblogicserver2.
    - weblogic_stop_command:
        default: 'sudo systemctl stop weblogic.service' # Example, adjust as needed
        required: false
        description: The command to execute on weblogicserver2 to stop the WebLogic service.
    - weblogic_timeout:
        default: 90000
        required: false

    # --- Oracle Server Inputs ---
    - oracle_host:
        required: true
        description: Hostname or IP address of the Oracle Linux server (oracleserver2).
    - oracle_ssh_port:
        default: 22
        required: false
    - oracle_ssh_user:
        required: true
        description: SSH username for oracleserver2.
    - oracle_ssh_password:
        required: true
        sensitive: true
        description: SSH password for oracleserver2.
    - oracle_stop_command:
        default: 'sudo systemctl stop oracle-db.service' # Example, adjust as needed (e.g., using sqlplus shutdown immediate)
        required: false
        description: The command to execute on oracleserver2 to stop the Oracle database service.
    - oracle_timeout:
        default: 120000 # Longer timeout for potential DB shutdown
        required: false

    # --- Cisco Router Inputs ---
    - router_host:
        required: true
        description: Hostname or IP address of the Cisco router (router2).
    - router_ssh_port:
        default: 22
        required: false
    - router_ssh_user:
        required: true
        description: SSH username for router2.
    - router_ssh_password:
        required: true
        sensitive: true
        description: SSH password for router2.
    - router_interface:
         # Example: 'GigabitEthernet0/2'. Port 2 might map to an interface name like this.
        required: true
        description: The specific interface name on router2 to shut down (e.g., GigabitEthernet0/2).
    - router_timeout:
        default: 90000
        required: false

  workflow:
    # Step 1: Stop WebLogic Service
    - stop_weblogic_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${weblogic_host}'
            - port: '${weblogic_ssh_port}'
            - username: '${weblogic_ssh_user}'
            - password:
                value: '${weblogic_ssh_password}'
                sensitive: true
            - command: '${weblogic_stop_command}'
            - pty: false # Typically false for service commands
            - timeout: '${weblogic_timeout}'
        publish:
          - weblogic_stop_result: '${return_result}'
          - weblogic_stop_code: '${return_code}'
        navigate:
          - SUCCESS: stop_oracle_service
          - FAILURE: on_failure # Allow proceeding even if one service fails? Or fail hard? Let's fail hard for now.

    # Step 2: Stop Oracle Service
    - stop_oracle_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${oracle_host}'
            - port: '${oracle_ssh_port}'
            - username: '${oracle_ssh_user}'
            - password:
                value: '${oracle_ssh_password}'
                sensitive: true
            - command: '${oracle_stop_command}'
            - pty: false # Typically false for service commands
            - timeout: '${oracle_timeout}'
        publish:
          - oracle_stop_result: '${return_result}'
          - oracle_stop_code: '${return_code}'
        navigate:
          - SUCCESS: shutdown_router_port
          - FAILURE: on_failure # Fail hard if DB doesn't stop

    # Step 3: Shutdown Router Port (Disconnect from Network)
    - shutdown_router_port:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${router_host}'
            - port: '${router_ssh_port}'
            - username: '${router_ssh_user}'
            - password:
                value: '${router_ssh_password}'
                sensitive: true
            # Cisco commands to enter config mode, select interface, and shut it down
            - command: "configure terminal\ninterface ${router_interface}\nshutdown\nend"
            - pty: true  # Often needed for interactive-like sessions and config mode on network devices
            - timeout: '${router_timeout}'
        publish:
          - router_shutdown_result: '${return_result}'
          - router_shutdown_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

    # Failure Handling Step
    - on_failure:
        do:
          io.cloudslang.base.utils.do_nothing: [] # Placeholder for potential error logging/reporting
        navigate:
          - SUCCESS: FAILURE # Transition flow to FAILURE result

  outputs:
    - weblogic_stop_result: '${weblogic_stop_result}'
    - weblogic_stop_code: '${weblogic_stop_code}'
    - oracle_stop_result: '${oracle_stop_result}'
    - oracle_stop_code: '${oracle_stop_code}'
    - router_shutdown_result: '${router_shutdown_result}'
    - router_shutdown_code: '${router_shutdown_code}'

  results:
    - SUCCESS
    - FAILURE
