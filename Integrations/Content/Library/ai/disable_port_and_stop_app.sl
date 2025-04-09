namespace: ai

imports:
  ssh: io.cloudslang.base.ssh

flow:
  name: disable_port_and_stop_app

  inputs:
    # Router Inputs
    - router_host:
        required: true
    - router_username:
        required: true
    - router_password:
        required: true
        sensitive: true
    - router_interface: # e.g., GigabitEthernet0/1, FastEthernet0/0
        required: true
    # Server Inputs
    - server_host:
        required: true
    - server_username:
        required: true
    - server_password:
        required: true
        sensitive: true
    - app_service_name: # e.g., nginx, httpd, tomcat, myapp.service
        required: true

  workflow:
    - disable_router_interface:
        do:
          ssh.ssh_command:
            - host: ${router_host}
            - username: ${router_username}
            - password:
                value: ${router_password}
                sensitive: true
            # IMPORTANT: The exact commands depend heavily on the router vendor (Cisco IOS, Juniper Junos, etc.)
            # This is a generic Cisco IOS example. Adjust commands as needed.
            # Using \n assumes the SSH operation/router can handle multi-line commands this way.
            # More complex scenarios might require expect operations or dedicated network modules.
            - command: "configure terminal\ninterface ${router_interface}\nshutdown\nend\nwrite memory"
            # Alternative for routers needing separate commands or different save commands:
            # - command: "configure terminal"
            # --- Followed by steps for interface, shutdown, end, save ---
            # Or use specific network operations if available in your CloudSlang content packs.
        publish:
          - router_disable_result: '${return_result}'
          - router_disable_error: '${error_message}'
        navigate:
          - SUCCESS: stop_server_app # If router command succeeds, proceed to stop the app
          - FAILURE: on_failure     # If router command fails, go to failure handler

    - stop_server_app:
        do:
          ssh.ssh_command:
            - host: ${server_host}
            - username: ${server_username}
            - password:
                value: ${server_password}
                sensitive: true
            # Command to stop the application service. Assumes systemd and sudo privileges.
            # Adjust if using different init systems (e.g., 'service <name> stop') or no sudo needed.
            # Ensure the user has permissions to stop the service (e.g., passwordless sudo).
            - command: "sudo systemctl stop ${app_service_name}"
        publish:
          - app_stop_result: '${return_result}'
          - app_stop_error: '${error_message}'
        navigate:
          - SUCCESS: SUCCESS # If app stop succeeds, the flow is successful
          - FAILURE: on_failure # If app stop fails, go to failure handler

  results:
    - SUCCESS
    - FAILURE
