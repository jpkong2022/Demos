namespace: ai
# Define the workflow name
# Define the flow
flow:
  name: GetCpuUtilization
  begin:
    # Step 1: Connect to the Linux Server (SSH)
    - ssh:
        host: ${server_ip}  # Replace with the actual server IP
        username: ${username}  # Replace with the SSH username
        password: ${password}  # Replace with the SSH password
        command: "top -n 1 -b | grep 'Cpu(s)'"
      publish:
        - cpu_output: "${ssh.result}"

    # Step 2: Parse the Output
    - python_script:
        script: |
          cpu_line = input['cpu_output'].splitlines()[0]
          cpu_utilization = cpu_line.split(',')[3].split()[0]
          return {'cpu_utilization': cpu_utilization}
      publish:
        - cpu_utilization: "${python_script.result['cpu_utilization']}"

    # Step 3: Return the Result
    - end:
        result: "${cpu_utilization}"
