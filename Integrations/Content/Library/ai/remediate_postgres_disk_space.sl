namespace: ai
flow:
  name: remediate_postgres_disk_space
  workflow:
    - free_space_and_expand_drive:
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
            - script: >
                Remove-Item -Path 'C:\Windows\Temp\*' -Recurse -Force -ErrorAction SilentlyContinue;
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue;
                $supportedSize = Get-PartitionSupportedSize -DriveLetter C -ErrorAction SilentlyContinue;
                if ($null -ne $supportedSize) { Resize-Partition -DriveLetter C -Size $supportedSize.SizeMax -ErrorAction SilentlyContinue }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
