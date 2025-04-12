namespace: ai
flow:
  name: telnet_cisco_show_banner
  inputs:
    - router_ip:
        required: true
    - username:
        required: true
    - password:
        required: true
        sensitive: true
    - banner_command:
        default: 'show banner motd' # Or 'show banner login', 'show running-config | include banner', etc.
        required: false
    - port:
        default: '23'
        required: false
    - timeout:
        default: '60000' # milliseconds
        required: false
    - prompt_regex:
        default: '.*[>#]\s*$' # Common regex for Cisco user exec (>) or privileged exec (#) prompts
        required: false
    - login_prompt_regex:
        default: 'Username:\s*$' # Common username prompt
        required: false
    - password_prompt_regex:
        default: 'Password:\s*$' # Common password prompt
        required: false
  workflow:
    - run_telnet_command:
        do:
          io.cloudslang.base.telnet.telnet_command:
            - host: ${router_ip}
            - port: ${port}
            - username: ${username}
            - password:
                value: ${password}
                sensitive: true
            - command: ${banner_command}
            - timeout: ${timeout}
            - prompt_regex: ${prompt_regex}
            - login_prompt_regex: ${login_prompt_regex}
            - password_prompt_regex: ${password_prompt_regex}
            # Optional: Add character_set, newline_sequence if needed
            # - character_set: UTF-8
            # - newline_sequence: CRLF
        publish:
          - banner_output: '${return_result}' # The output of the command
          - command_exception: '${exception}' # Capture any exception during execution
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure # Default failure transition
  outputs:
    - banner_output: '${banner_output}'
    - command_exception: '${command_exception}'
  results:
    - SUCCESS
    - FAILURE
