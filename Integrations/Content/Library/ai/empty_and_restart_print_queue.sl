namespace: ai
flow:
  name: empty_and_restart_print_queue
  inputs:
    - host:
        required: true
    - username:
        required: true
    - password:
        required: true
        sensitive: true
    - port:
        default: '5985'
        required: false
    - protocol:
        default: http
        required: false
    - auth_type:
        default: basic
        required: false
    - trust_all_roots:
        default: 'true'
        required: false
    - x_509_hostname_verifier:
        default: allow_all
        required: false
  workflow:
    - stop_print_spooler:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: '${host}'
            - port: '${port}'
            - protocol: '${protocol}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - auth_type: '${auth_type}'
            - script: "Stop-Service -Name Spooler -Force"
            - trust_all_roots: '${trust_all_roots}'
            - x_509_hostname_verifier: '${x_509_hostname_verifier}'
        publish:
          - stop_result: '${return_result}'
          - stop_error: '${stderr}'
        navigate:
          - SUCCESS: clear_print_queue_folder
          - FAILURE: on_failure
    - clear_print_queue_folder:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: '${host}'
            - port: '${port}'
            - protocol: '${protocol}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - auth_type: '${auth_type}'
            - script: "Remove-Item -Path C:\\Windows\\System32\\spool\\PRINTERS\\* -Force -Recurse -ErrorAction Stop"
            - trust_all_roots: '${trust_all_roots}'
            - x_509_hostname_verifier: '${x_509_hostname_verifier}'
        publish:
          - clear_result: '${return_result}'
          - clear_error: '${stderr}'
        navigate:
          - SUCCESS: start_print_spooler
          - FAILURE: on_failure
    - start_print_spooler:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: '${host}'
            - port: '${port}'
            - protocol: '${protocol}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - auth_type: '${auth_type}'
            - script: "Start-Service -Name Spooler"
            - trust_all_roots: '${trust_all_roots}'
            - x_509_hostname_verifier: '${x_509_hostname_verifier}'
        publish:
          - start_result: '${return_result}'
          - start_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - stop_result: '${stop_result}'
    - clear_result: '${clear_result}'
    - start_result: '${start_result}'
    - error_message: "Failed to stop spooler: ${stop_error}. Failed to clear queue: ${clear_error}. Failed to start spooler: ${start_error}."
  results:
    - SUCCESS
    - FAILURE
