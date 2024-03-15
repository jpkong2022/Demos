namespace: ai
# Define the workflow name
flow:
name: GetLinuxCpuUtilization

# Define workflow inputs
inputs:
  server_ip:
    description: IP address of the Linux server
    type: string

# Define workflow outputs
outputs:
  cpu_utilization:
    description: CPU utilization percentage
    type: string

# Define workflow stages
stages:
  - name: Get CPU info
    steps:
      - name: Run script - Get CPU utilization
        type: script
        script: |
          # Use 'sh' interpreter (modify if needed)
          sh """
          # Get CPU idle time using 'vmstat 1 2' (capture two samples) | awk '{print $13}' | tail -n 1
          idle_time=$(vmstat 1 2 | awk '{print $13}' | tail -n 1)
          # Get total CPU time using 'vmstat 1 2' (capture two samples) | awk '{print $14 + $15}' | tail -n 1
          total_time=$(vmstat 1 2 | awk '{print $14 + $15}' | tail -n 1)
          # Calculate CPU utilization (percentage)
          cpu_utilization=$((100 - (idle_time * 100) / total_time))
          # Set output variable
          setOutput "cpu_utilization" "$cpu_utilization"
          """

  - name: Set output
    steps:
      - name: Set workflow output - CPU utilization
        type: script
        script: |
          setOutput "cpu_utilization" <% $.GetCPUinfo.cpu_utilization %>

