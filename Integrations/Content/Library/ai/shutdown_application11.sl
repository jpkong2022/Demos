namespace: ai

flow:
  name: shutdown_application11

  inputs:
    # --- Inputs specific to Application 11 would go here ---
    # Since the topology for Application11 is not provided,
    # we need generic inputs for the server(s) and command(s) involved.
    # You would replace these with specific details or add steps
    # if Application11 involves multiple components (e.g., web, app, db).

    - target_host:
        description: IP address or hostname of the server hosting Application11 or its component to shut down.
        required: true
    - shutdown_command:
        description: The specific command required to shut down Application11 or its component (e.g., 'sudo systemctl stop app11.service', '/opt/app11/bin/stop.sh').
        required: true
    - os_type:
        description: Operating system type ('linux' or 'windows') to determine which command execution method to use.
        required: true
        default: 'linux' # Assuming Linux is more common based on examples
    - username:
        description: Username for connecting to the target host.
        required: true
    - password:
        description: Password for connecting to the target host.
        required: true
        sensitive: true
    - ssh_port:
        description: SSH port for Linux connections.
        default: 22
        required: false
    - ssh_timeout:
        description: SSH command timeout in milliseconds.
        default: 90000
        required: false
    - use_pty:
        description: Whether to use PTY for SSH connection (often needed for service stop/start).
        default: true
        required: false
    # Add inputs for Windows specific connection if needed (e.g., WinRM port, auth type)

  workflow:
    # Step 1: Determine execution path based on OS Type
    - check_os_type:
        do:
          io.cloudslang.base.utils.equals:
            - first_value: '${os_type}'
            - second_value: 'linux'
        navigate:
          - EQUAL: execute_linux_shutdown # If os_type is 'linux'
          - NOT_EQUAL: execute_windows_shutdown # Assuming anything else is 'windows' for this example

    # Step 2a: Execute shutdown command on Linux via SSH
    - execute_linux_shutdown:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${target_host}'
            - port: '${ssh_port}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - command: '${shutdown_command}'
            - pty: '${use_pty}'
            - timeout: '${ssh_timeout}'
        publish:
          - command_output: '${return_result}'
          - return_code: '${return_code}'
        navigate:
          # Check return code - 0 usually means success for shutdown scripts/commands
          - SUCCESS: check_linux_return_code
          - FAILURE: on_failure # Handle SSH connection errors etc.

    # Step 3a: Check Linux command return code
    - check_linux_return_code:
        do:
          io.cloudslang.base.utils.equals:
            - first_value: '${return_code}'
            - second_value: '0'
        navigate:
          - EQUAL: SUCCESS # Command executed successfully
          - NOT_EQUAL: FAILURE # Command executed but returned non-zero (error)

    # Step 2b: Execute shutdown command on Windows
    # NOTE: The example provided uses io.cloudslang.base.cmd.run_command, which runs LOCALLY.
    # To run on a REMOTE Windows machine, you'd typically use PowerShell/WinRM operations
    # (e.g., io.cloudslang.base.powershell.ps_script) or SSH if enabled on the Windows host.
    # This example uses SSH assuming it's configured on the Windows target.
    # If WinRM is preferred, replace this step with the appropriate ps_script operation.
    - execute_windows_shutdown:
        do:
          # Using ssh_command for Windows (requires SSH Server on Windows target)
          # Alternatively, replace with io.cloudslang.base.powershell.ps_script if using WinRM
          io.cloudslang.base.ssh.ssh_command:
            - host: '${target_host}'
            - port: '${ssh_port}' # Ensure SSH port is correct for Windows SSH Server
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - command: '${shutdown_command}' # e.g., 'Stop-Service -Name App11Service' or 'C:\App11\bin\shutdown.bat'
            - timeout: '${ssh_timeout}'
            # pty might not be needed/supported depending on Windows SSH server
        publish:
          - command_output: '${return_result}'
          - return_code: '${return_code}'
        navigate:
          - SUCCESS: check_windows_return_code
          - FAILURE: on_failure # Handle SSH/WinRM connection errors etc.

    # Step 3b: Check Windows command return code
    - check_windows_return_code:
        do:
          io.cloudslang.base.utils.equals:
            - first_value: '${return_code}'
            - second_value: '0'
        navigate:
          - EQUAL: SUCCESS # Command executed successfully
          - NOT_EQUAL: FAILURE # Command executed but returned non-zero (error)

  outputs:
    - command_output: '${command_output}'
    - return_code: '${return_code}'

  results:
    - SUCCESS
    - FAILURE
