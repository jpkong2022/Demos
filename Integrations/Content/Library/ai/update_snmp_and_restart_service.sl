namespace: ai
flow:
  name: update_snmp_and_restart_service
  inputs:
    # Linux Server Inputs
    - linux_host:
        required: true
    - linux_username:
        required: true
    - linux_password:
        required: true
        sensitive: true
    - new_community_string:
        required: true
    - snmp_config_file:
        default: /etc/snmp/snmpd.conf
        required: false
    - snmp_service_name:
        default: snmpd
        required: false
    - ssh_port:
        default: '22'
        required: false
    - ssh_timeout:
        default: '90000' # milliseconds
        required: false

    # Windows Server Inputs
    - windows_host:
        required: true
    - windows_username:
        required: true
    - windows_password:
        required: true
        sensitive: true
    - windows_service_name:
        required: true

    # Optional Proxy Inputs
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true

  workflow:
    # Step 1: Update SNMP Community String on Linux Server
    - update_snmp_config:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${linux_host}
            - port: ${ssh_port}
            - username: ${linux_username}
            - password:
                value: ${linux_password}
                sensitive: true
            # This command attempts to replace an existing 'rocommunity' line.
            # Adjust the 'sed' command based on your specific snmpd.conf structure.
            # It might be safer to remove old lines and add a new one.
            # This example replaces the first line starting with 'rocommunity' or adds it if not found.
            # Assumes passwordless sudo or appropriate sudoers configuration.
            - command: |
                if grep -q '^rocommunity' ${snmp_config_file}; then
                  sudo sed -i '/^rocommunity/c\rocommunity ${new_community_string}' ${snmp_config_file}
                else
                  echo "rocommunity ${new_community_string}" | sudo tee -a ${snmp_config_file} > /dev/null
                fi
            - timeout: ${ssh_timeout}
            - proxy_host: ${proxy_host}
            - proxy_port: ${proxy_port}
            - proxy_username: ${proxy_username}
            - proxy_password:
                value: ${proxy_password}
                sensitive: true
        publish:
          - snmp_update_stdout: ${return_result}
          - snmp_update_stderr: ${error_message} # Capturing stderr if available
        navigate:
          - SUCCESS: restart_snmp_service
          - FAILURE: on_failure

    # Step 2: Restart SNMP Service on Linux Server
    - restart_snmp_service:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${linux_host}
            - port: ${ssh_port}
            - username: ${linux_username}
            - password:
                value: ${linux_password}
                sensitive: true
            # Command to restart the SNMP service. Adjust based on Linux distribution (systemctl vs service)
            - command: "sudo systemctl restart ${snmp_service_name} || sudo service ${snmp_service_name} restart"
            - timeout: ${ssh_timeout}
            - proxy_host: ${proxy_host}
            - proxy_port: ${proxy_port}
            - proxy_username: ${proxy_username}
            - proxy_password:
                value: ${proxy_password}
                sensitive: true
        publish:
          - snmp_restart_stdout: ${return_result}
          - snmp_restart_stderr: ${error_message} # Capturing stderr if available
        navigate:
          - SUCCESS: restart_windows_service
          - FAILURE: on_failure # Or potentially a specific failure path for SNMP restart

    # Step 3: Restart Application Service on Windows Server
    - restart_windows_service:
        do:
          # Using PowerShell is generally recommended for Windows management tasks
          io.cloudslang.base.powershell.powershell_script:
            - host: ${windows_host}
            - username: ${windows_username}
            - password:
                value: ${windows_password}
                sensitive: true
            # PowerShell script to restart the service
            - script: "Restart-Service -Name '${windows_service_name}' -Force -ErrorAction Stop"
            - proxy_host: ${proxy_host}
            - proxy_port: ${proxy_port}
            - proxy_username: ${proxy_username}
            - proxy_password:
                value: ${proxy_password}
                sensitive: true
            # Add other relevant powershell options if needed (e.g., auth_type, winrm_timeout)
        publish:
          - service_restart_result: ${return_result}
          - service_restart_error: ${error_message}
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - snmp_update_output: ${snmp_update_stdout}
    - snmp_restart_output: ${snmp_restart_stdout}
    - windows_service_restart_output: ${service_restart_result}
    - error_details: ${error_message} # Captures error from the last failed step

  results:
    - SUCCESS
    - FAILURE
