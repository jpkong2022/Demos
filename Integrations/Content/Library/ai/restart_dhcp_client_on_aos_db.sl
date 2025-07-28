namespace: ai
flow:
  name: restart_dhcp_client_on_aos_db
  workflow:
    - restart_dhcp_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.26.86
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('admin_password')}"
                sensitive: true
            - auth_type: basic
            - script: "Restart-Service -Name 'dhcp'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - service_restart_result: '${return_result}'
          - service_restart_error: '${stderr}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - service_restart_result: '${service_restart_result}'
    - service_restart_error: '${service_restart_error}'
  results:
    - SUCCESS
    - FAILURE
