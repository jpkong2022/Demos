namespace: ai
workflow:
  name: Get_CPU_Utilization
  version: '1.0'
  description: |
    A workflow to retrieve CPU utilization of a Linux server using CloudSlang.

  inputs:
    - server_ip
    - username
    - password
    - ssh_port: '22'  # Default SSH port

  tasks:
    get_cpu_utilization:
      action: csactions:run_ssh_command
      inputs:
        host: "${server_ip}"
        port: "${ssh_port}"
        username: "${username}"
        password: "${password}"
        command: "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}'"
      publish:
        cpu_utilization: "${$Output}"

  outputs:
    - cpu_utilization