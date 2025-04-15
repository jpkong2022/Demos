namespace: ai
flow:
  name: run_cisco_banner_command
  inputs:
    - host:
        required: true
        description: The IP address or hostname of the Cisco device.
    - port:
        default: 22
        required: false
        description: The SSH port on the Cisco device (default is 22).
    - username:
        required: true
        description: The username for SSH login.
    - password:
        required: true
        sensitive: true
        description: The password for SSH login.
    - banner_text:
        required: true
        description: The text for the MOTD banner. Use a delimiter character not present in your text (e.g., #, @, ~).
    - banner_delimiter:
        default: '#'
        required: false
        description: The delimiter character to start and end the banner text input in Cisco config mode.
    - enable_password:
        required: false
        sensitive: true
        description: The enable password, if required to enter privileged EXEC mode.
    - timeout:
        default: 90000 # 90 seconds
        required: false
        description: SSH command timeout in milliseconds.
    - pty:
        default: true # Cisco often requires a PTY
        required: false
        description: Whether to allocate a pseudo-terminal (pty). Recommended for interactive sessions like Cisco config.

  workflow:
    - set_banner_command:
        # Note: This assumes basic login takes you to user EXEC mode (>).
        # It handles optional enable password and constructs the multi-line command.
        # It uses '\n' for newlines, which ssh_command should handle with pty=true.
        do:
          io.cloudslang.base.utils.jinja_template_generator:
            - template: |
                {%- set enable_cmd = '' -%}
                {%- if enable_password -%}
                {%- set enable_cmd = 'enable\n' + enable_password + '\n' -%}
                {%- endif -%}
                {{ enable_cmd }}configure terminal
                banner motd {{ banner_delimiter }}
                {{ banner_text }}
                {{ banner_delimiter }}
                end
                exit
            - context:
                enable_password: ${enable_password if enable_password is not none else ''}
                banner_text: ${banner_text}
                banner_delimiter: ${banner_delimiter}
        publish:
          - full_command: '${result}'
        navigate:
          - SUCCESS: execute_ssh_command
          - FAILURE: on_failure

    - execute_ssh_command:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: ${host}
            - port: ${port}
            - username: ${username}
            - password:
                value: ${password}
                sensitive: true
            # The command includes enable (if needed), conf t, banner, end, exit
            - command: ${full_command}
            - timeout: ${timeout}
            - pty: ${pty} # Important for Cisco multi-line/config commands
            # Add private_key_file input handling here if needed instead of password
            # - private_key_file:
            #     value: ${private_key_file}
            #     sensitive: true
        publish:
          - command_output: '${return_result}'
          - return_code: '${return_code}'
          - error_message: '${error_message}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - command_output: '${command_output}'
    - return_code: '${return_code}'
    - error_message: '${error_message}'

  results:
    - SUCCESS
    - FAILURE
