namespace: ai

flow:
  name: shutdown_application2

  inputs:
    # Inputs for WebLogic Server (weblogicserver2)
    - weblogic_host:
        required: true
        description: Hostname or IP address of the WebLogic Linux server (weblogicserver2).
    - weblogic_user:
        required: true
        description: SSH username for the WebLogic server.
    - weblogic_password:
        required: true
        sensitive: true
        description: SSH password for the WebLogic server.
    - weblogic_stop_command:
        default: "sudo systemctl stop weblogic.service # Adjust this command as needed"
        required: false
        description: The command to stop the WebLogic service/process on weblogicserver2.

    # Inputs for Oracle Server (oracleserver2)
    - oracle_host:
        required: true
        description: Hostname or IP address of the Oracle Linux server (oracleserver2).
    - oracle_user:
        required: true
        description: SSH username for the Oracle server.
    - oracle_password:
        required: true
        sensitive: true
        description: SSH password for the Oracle server.
    - oracle_stop_command:
        default: "sudo systemctl stop oracle-db.service # Adjust this command as needed (e.g., using dbshut)"
        required: false
        description: The command to stop the Oracle database/service on oracleserver2.

    # Inputs for Cisco Router (router2 - Port 2 - Optional: disabling port might be too drastic)
    # Decided against including router port shutdown by default as it's often too disruptive for just an app shutdown.
    # If needed, add inputs like router_host, router_user, router_password and a step using ssh_command with Cisco commands.

    - ssh_timeout:
        default: 90000 # Default timeout 90 seconds
        required: false

  workflow:
    # Step 1: Stop WebLogic service on weblogicserver2
    - stop_weblogic_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${weblogic_host}
            - username: ${weblogic_user}
            - password:
                value: ${weblogic_password}
                sensitive: true
            - command: ${weblogic_stop_command}
            - timeout: ${ssh_timeout}
            - pty: true # May be needed depending on sudo configuration
        publish:
          - weblogic_stop_result: ${return_result}
          - weblogic_stop_code: ${return_code}
        navigate:
          - SUCCESS: stop_oracle_server # Proceed to stop Oracle if WebLogic stop succeeds
          - FAILURE: on_failure        # Go to failure state if WebLogic stop fails

    # Step 2: Stop Oracle service on oracleserver2
    - stop_oracle_server:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${oracle_host}
            - username: ${oracle_user}
            - password:
                value: ${oracle_password}
                sensitive: true
            - command: ${oracle_stop_command}
            - timeout: ${ssh_timeout}
            - pty: true # May be needed depending on sudo configuration
        publish:
          - oracle_stop_result: ${return_result}
          - oracle_stop_code: ${return_code}
        navigate:
          - SUCCESS: SUCCESS           # Final success if Oracle stop succeeds
          - FAILURE: on_failure        # Go to failure state if Oracle stop fails

    # Optional Step 3: Disable Cisco Router Port 2 (router2) - Use with caution!
    # - disable_router_port:
    #     do:
    #       io.cloudslang.base.ssh.ssh_command:
    #         - host: ${router_host} # Add router_host input if using this
    #         - username: ${router_user} # Add router_user input if using this
    #         - password:
    #             value: ${router_password} # Add router_password input if using this
    #             sensitive: true
    #         - command: "configure terminal\ninterface <interface_name_for_port_2>\nshutdown\nend\nwrite memory" # Replace <interface_name_for_port_2>
    #         - pty: true
    #         - timeout: ${ssh_timeout}
    #     publish:
    #       - router_disable_result: ${return_result}
    #       - router_disable_code: ${return_code}
    #     navigate:
    #       - SUCCESS: SUCCESS
    #       - FAILURE: on_failure

  outputs:
    - weblogic_stop_result: ${weblogic_stop_result}
    - weblogic_stop_code: ${weblogic_stop_code}
    - oracle_stop_result: ${oracle_stop_result}
    - oracle_stop_code: ${oracle_stop_code}
    # - router_disable_result: ${router_disable_result} # Uncomment if router step is used
    # - router_disable_code: ${router_disable_code}     # Uncomment if router step is used

  results:
    - SUCCESS
    - FAILURE
