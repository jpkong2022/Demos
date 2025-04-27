namespace: ai
flow:
  name: execute_dir_on_iisserver
  workflow:
    - run_dir_command:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.16.125  # IP address of iisserver
            - port: '5985'         # Default WinRM port for http
            - protocol: http       # Assuming WinRM is configured for HTTP
            - username: administrator # Username for iisserver
            - password:
                value: "D4D5M4GKlug?&rD?Hwf?9e1Tj&ytKbDH" # Password for iisserver
                sensitive: true
            - auth_type: basic     # Assuming Basic authentication
            - script: dir          # The command to execute
            - trust_all_roots: 'true' # Necessary if using self-signed certs or http
            - x_509_hostname_verifier: allow_all # Necessary if using self-signed certs or http
        publish:
          - dir_output: '${return_result}' # Publish the standard output of the command
          - return_code: '${return_code}'   # Publish the exit code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - dir_output: '${dir_output}'
    - return_code: '${return_code}'
  results:
    - SUCCESS
    - FAILURE
