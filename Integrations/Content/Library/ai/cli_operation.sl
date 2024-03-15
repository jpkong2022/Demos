namespace: ai
flow:
  name: Get_CPU_Utilization_Linux_Server
  description: "A flow to retrieve CPU utilization of a Linux server using CloudSlang."
  steps:
    - name: Input
      type: begin
      next-step: get_cpu_utilization

    - name: get_cpu_utilization
      type: operation
      operation:
        ref: "csactions.run_ssh_command"
        inputs:
          host: "${input.server_ip}"
          port: "${input.ssh_port}"
          username: "${input.username}"
          password: "${input.password}"
          command: "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}'"
      next-step: Output

    - name: Output
      type: end
      outputs:
        - name: cpu_utilization
          value: "${result.Output}"
