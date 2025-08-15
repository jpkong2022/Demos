namespace: ai
flow:
  name: stop_aos_application
  workflow:
    - stop_aos_web_server:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.54.247
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('aosweb_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: "Stop-Service -Name 'AOS'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: stop_aos_db_server
          - FAILURE: on_failure
    - stop_aos_db_server:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('aosdb_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: "Stop-Service -Name 'postgresql-x64-12'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
