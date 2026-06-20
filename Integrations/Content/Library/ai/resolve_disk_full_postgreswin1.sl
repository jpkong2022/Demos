namespace: ai
flow:
  name: resolve_disk_full_postgreswin1
  workflow:
    - free_disk_space:
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
            - script: "Remove-Item -Path 'C:\\Windows\\Temp\\*' -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path 'C:\\Users\\administrator\\AppData\\Local\\Temp\\*' -Recurse -Force -ErrorAction SilentlyContinue; Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
