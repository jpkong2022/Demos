namespace: ai
flow:
  name: restart_specific_windows_services
  workflow:
    - restart_printer_on_iisserver:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.16.125  # iisserver IP
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "D4D5M4GKlug?&rD?Hwf?9e1Tj&ytKbDH"
                sensitive: true
            - auth_type: basic
            - script: Restart-Service -Name Spooler  # Service name for Printer is Spooler
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - iisserver_printer_restart_result: '${return_result}'
          - iisserver_printer_restart_code: '${return_code}'
        navigate:
          - SUCCESS: restart_scheduler_on_sqlserver
          - FAILURE: on_failure

    - restart_scheduler_on_sqlserver:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.16.125  # sqlserver IP
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "D4D5M4GKlug?&rD?Hwf?9e1Tj&ytKbDH"
                sensitive: true
            - auth_type: basic
            - script: Restart-Service -Name Schedule # Service name for Task Scheduler is Schedule
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - sqlserver_scheduler_restart_result: '${return_result}'
          - sqlserver_scheduler_restart_code: '${return_code}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - iisserver_printer_restart_result: '${iisserver_printer_restart_result}'
    - iisserver_printer_restart_code: '${iisserver_printer_restart_code}'
    - sqlserver_scheduler_restart_result: '${sqlserver_scheduler_restart_result}'
    - sqlserver_scheduler_restart_code: '${sqlserver_scheduler_restart_code}'

  results:
    - SUCCESS
    - FAILURE
