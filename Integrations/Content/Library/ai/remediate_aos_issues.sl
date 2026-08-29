namespace: ai
flow:
  name: remediate_aos_issues
  workflow:
    - free_disk_space_postgreswin1:
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
          - SUCCESS: rollback_apache_upgrade_apachewin1
          - FAILURE: on_failure
          
    - rollback_apache_upgrade_apachewin1:
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
            - script: "Stop-Service -Name 'AOS' -Force; Write-Output 'Rolling back Apache web server upgrade to previous version...'; Start-Service -Name 'AOS'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
          
  results:
    - SUCCESS
    - FAILURE
