namespace: ai

flow:
  name: disable_network_and_shutdown_app2

  inputs:
    # Router connection details
    - router_host:
        required: true
        default: router2 # Logical name from description, replace with actual IP/hostname
    - router_port:
        default: 22
        required: false
    - router_username:
        required: true
    - router_password:
        required: true
        sensitive: true

    # WebLogic Server connection details
    - weblogic_host:
        required: true
        default: weblogicserver2 # Logical name from description, replace with actual IP/hostname
    - weblogic_port:
        default: 22
        required: false
    - weblogic_username:
        required: true
        default: centos # Example username, adjust as needed
    - weblogic_password:
        required: true
        sensitive: true

    # Oracle Server connection details
    - oracle_host:
        required: true
        default: oracleserver2 # Logical name from description, replace with actual IP/hostname
    - oracle_port:
        default: 22
        required: false
    - oracle_username:
        required: true
        default: centos # Example username, adjust as needed (might need 'oracle' user or sudo)
    - oracle_password:
        required: true
        sensitive: true

    # Specific details (customize these)
    - router_interface:
        required: true
        default: "GigabitEthernet0/2" # Example interface for port 2, ADJUST AS NEEDED
    - weblogic_stop_command:
        required: true
        default: "sudo systemctl stop weblogic.service" # Example command, ADJUST AS NEEDED (e.g., path to stopWebLogic.sh)
    - oracle_stop_command:
        required: true
        default: "sudo systemctl stop oracle-database.service" # Example command, ADJUST AS NEEDED (e.g., dbshut script or sqlplus command)

  workflow:
    - disable_router_port:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${router_host}
            - port: ${router_port}
            - username: ${router_username}
            - password:
                value: ${router_password}
                sensitive: true
            # Command sequence for Cisco IOS to disable an interface
            - command: |
                configure terminal
                interface ${router_interface}
                shutdown
                end
                exit
            - pty: true # Often needed for interactive-like sessions on network devices
            - timeout: 90000
        publish:
          - router_disable_output: '${return_result}'
          - router_disable_return_code: '${return_code}'
        navigate:
          - SUCCESS: stop_weblogic_server
          - FAILURE: on_failure

    - stop_weblogic_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${weblogic_host}
            - port: ${weblogic_port}
            - username: ${weblogic_username}
            - password:
                value: ${weblogic_password}
                sensitive: true
            - command: ${weblogic_stop_command} # Use the input command
            - pty: false # Usually not needed for simple service stop
            - timeout: 120000 # Allow more time for service shutdown
        publish:
          - weblogic_stop_output: '${return_result}'
          - weblogic_stop_return_code: '${return_code}'
        navigate:
          # Proceed even if weblogic stop fails? Or fail hard? Let's proceed to stop Oracle.
          # If strict dependency is needed, change SUCCESS path for non-zero return code check if needed.
          - SUCCESS: stop_oracle_server
          - FAILURE: stop_oracle_server # Attempt to stop Oracle even if WebLogic fails

    - stop_oracle_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${oracle_host}
            - port: ${oracle_port}
            - username: ${oracle_username}
            - password:
                value: ${oracle_password}
                sensitive: true
            - command: ${oracle_stop_command} # Use the input command
            - pty: false # Usually not needed for simple service stop
            - timeout: 180000 # Allow even more time for DB shutdown
        publish:
          - oracle_stop_output: '${return_result}'
          - oracle_stop_return_code: '${return_code}'
        navigate:
          # Check results from previous steps if needed here, or just proceed to SUCCESS/FAILURE
          - SUCCESS: check_final_status
          - FAILURE: on_failure # If SSH itself fails

    - check_final_status:
        # This is a conceptual step. You might add checks here based on return codes
        # from previous steps if more complex success/failure logic is needed.
        # For this example, we assume reaching here after oracle command means success.
        # A more robust flow would check router_disable_return_code, weblogic_stop_return_code, etc.
        do:
          io.cloudslang.base.utils.do_nothing: [] # Placeholder step
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure # Should not happen with do_nothing

  outputs:
    - router_disable_status: '${router_disable_return_code}'
    - weblogic_stop_status: '${weblogic_stop_return_code}'
    - oracle_stop_status: '${oracle_stop_return_code}'
    - final_message: # Example of combining results
        value: >
          Router disable RC: ${router_disable_return_code}.
          WebLogic stop RC: ${weblogic_stop_return_code}.
          Oracle stop RC: ${oracle_stop_return_code}.

  results:
    - SUCCESS # Flow completed (individual steps might have non-zero return codes)
    - FAILURE # Flow failed due to SSH connection error or navigation to on_failure
