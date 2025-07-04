namespace: ai
flow:
  name: read_windows_csv_and_extract_columns
  inputs:
    - host:
        default: 172.31.26.86
        required: false
    - username:
        default: administrator
        required: false
    - password:
        value: "${get_sp('admin_password')}"
        sensitive: true
        required: true
    - csv_path:
        default: 'c:\temp\levels.csv'
        required: false
    - port:
        default: '5985'
        required: false
    - protocol:
        default: http
        required: false
  workflow:
    - read_csv_file:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: '${host}'
            - port: '${port}'
            - protocol: '${protocol}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - auth_type: basic
            - script: |
                $filePath = "${csv_path}"
                if (Test-Path $filePath) {
                    try {
                        $csvData = Import-Csv -Path $filePath
                        # Ensure columns exist before trying to access them
                        $properties = $csvData | Get-Member -MemberType NoteProperty
                        $level1Data = if ($properties.Name -contains 'Level1') { @($csvData.Level1) } else { @() }
                        $level2Data = if ($properties.Name -contains 'Level2') { @($csvData.Level2) } else { @() }
                        $level3Data = if ($properties.Name -contains 'Level3') { @($csvData.Level3) } else { @() }
                        
                        $result = @{
                            Level1 = $level1Data
                            Level2 = $level2Data
                            Level3 = $level3Data
                        }
                        $result | ConvertTo-Json -Compress
                    } catch {
                        Write-Error "Failed to read or process CSV file: $_"
                        exit 1
                    }
                } else {
                    Write-Error "CSV file not found at $filePath"
                    exit 1
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - json_output: '${return_result}'
          - error_message: '${stderr}'
        navigate:
          - SUCCESS: parse_json_data
          - FAILURE: on_failure
    - parse_json_data:
        do:
          io.cloudslang.base.python.python_action:
            - script: |
                import json
                try:
                  data = json.loads(json_string)
                  level1_values = data.get('Level1', [])
                  level2_values = data.get('Level2', [])
                  level3_values = data.get('Level3', [])
                except Exception as e:
                  error = str(e)
                  level1_values = []
                  level2_values = []
                  level3_values = []
            - python_inputs:
                - json_string: '${json_output}'
        publish:
          - level1_values: '${level1_values}'
          - level2_values: '${level2_values}'
          - level3_values: '${level3_values}'
          - parsing_error: '${error}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - level1_entries: '${level1_values}'
    - level2_entries: '${level2_values}'
    - level3_entries: '${level3_values}'
    - powershell_error: '${error_message}'
    - parsing_error: '${parsing_error}'
  results:
    - SUCCESS
    - FAILURE
