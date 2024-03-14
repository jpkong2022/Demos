namespace: ai
flow:
  name: get_cpu_usage
  description: |
    This workflow retrieves the CPU usage of a Linux server based on its IP address.
  inputs:
    - name: ip_address
      required: true
      description: The IP address of the Linux server to query.

  steps:
    - name: ssh_command
      action: "ssh:run_command"
      inputs:
        host: "${ip_address}"
        port: "22"
        username: "your_ssh_username"
        password: "your_ssh_password"
        command: "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}'"

    - name: parse_cpu_usage
      action: "string:split"
      inputs:
        delimiter: "\n"
        text: "${ssh_command.result}"
      outputs:
        - name: cpu_usage_lines

    - name: extract_cpu_usage
      action: "string:split"
      inputs:
        delimiter: " "
        text: "${cpu_usage_lines[0]}"
      outputs:
        - name: cpu_usage_values

  outputs:
    - name: cpu_usage_percentage
      value: "${cpu_usage_values[0]}"
    - name: raw_results
      value: "${ssh_command.result}"