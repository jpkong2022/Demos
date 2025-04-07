namespace: ai

flow:
  name: cleanup3
  inputs:
    - host:
        description: The hostname or IP address of the server to ping.
        required: true
    - ping_count:
        description: Number of ping packets to send.
        required: false
        default: '4' # Default to 4 pings like standard ping command
    - timeout:
        description: Timeout in milliseconds to wait for each reply.
        required: false
        default: '5000' # Default to 5 seconds
  workflow:
    - ping_the_host:
        do:
          io.cloudslang.base.network.ping:
            - host: ${host}
            - ping_count: ${ping_count}
            - timeout: ${timeout}
        publish:
          - return_code: ${return_code}
          - return_result: ${return_result} # Raw output from the ping command
          - packet_loss: ${packet_loss} # Percentage of packets lost
        navigate:
          - SUCCESS: SUCCESS # Continue if ping command executed (regardless of reachability)
          - FAILURE: FAILURE # If the operation itself failed to run

    - ON_SUCCESS:
        # You could add logic here to check return_code or packet_loss
        # For this basic example, just return success if the ping command ran.
        return: SUCCESS

    - ON_FAILURE:
       return: FAILURE
  results:
    - SUCCESS
    - FAILURE