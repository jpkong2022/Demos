namespace: ai

workflow:
  name: Get_CPU_Utilization_Linux_Server
  description: "A workflow to retrieve CPU utilization of a Linux server using CloudSlang."
  inputSchema:
    - name: server_ip
      required: true
      type: string
    - name: username
      required: true
      type: string
    - name: password
      required: true
      type: string
    - name: ssh_port
      type: string
      default: "22"  # Default SSH port

tasks:
  task1:
    description: "Retrieve CPU utilization"
    python_action: "csactions.run_ssh_command"
    inputs:
      host: "${input.server_ip}"
      port: "${input.ssh_port}"
      username: "${input.username}"
      password: "${input.password}"
      command: "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}'"
    publish:
      cpu_utilization: "${result.Output}"

outputs:
  - name: cpu_utilization
    description: "The CPU utilization percentage of the Linux server."
