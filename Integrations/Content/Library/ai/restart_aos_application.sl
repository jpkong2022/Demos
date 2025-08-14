namespace: ai
flow:
  name: restart_aos_application
  workflow:
    - restart_aos_db:
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
            - script: "Restart-Service -Name 'postgresql-x64-12'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - db_restart_result: '${return_result}'
        navigate:
          - SUCCESS: restart_aos_web
          - FAILURE: on_failure
    - restart_aos_web:
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
            - script: "Restart-Service -Name 'AOS'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - web_restart_result: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - db_restart_result: '${db_restart_result}'
    - web_restart_result: '${web_restart_result}'
  results:
    - SUCCESS
    - FAILURE
