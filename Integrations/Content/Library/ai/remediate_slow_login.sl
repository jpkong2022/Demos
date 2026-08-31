namespace: ai
flow:
  name: remediate_slow_login
  workflow:
    - free_disk_space_postgres:
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
            - script: "Remove-Item -Path 'C:\\Windows\\Temp\\*' -Recurse -Force -ErrorAction SilentlyContinue; Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: verify_apache_upgrade
          - FAILURE: on_failure

    - verify_apache_upgrade:
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
            - script: "Get-Service -Name 'AOS' | Where-Object {$_.Status -eq 'Running'}; Test-Path -Path 'C:\\tomcat_web_server\\conf\\server.xml'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  results:
    - SUCCESS
    - FAILURE
