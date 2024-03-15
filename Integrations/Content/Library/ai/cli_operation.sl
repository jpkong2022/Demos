namespace: ai
executions:
  - flow: get_cpu_utilization
    inputs:
      ip_address: ${ip_address}

flows:
  get_cpu_utilization:
    steps:
      - name: Get CPU Usage
        action: linux.get_cpu_usage
        input:
          ip_address: ${ip_address}
        publish:
          cpu_utilization: '${linux.get_cpu_usage.cpu_utilization}'
          results: '${linux.get_cpu_usage.results}'