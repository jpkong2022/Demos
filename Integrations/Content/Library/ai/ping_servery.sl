namespace: ai
imports:
  network: io.cloudslang.base.network

flow:
  name: ping_server

  inputs:
    - host:
        description: The hostname or IP address of the server to ping.
        required: true
    - ping_count:
        description: Number of ping packets to send.
        required: false
        default: '4'
    - timeout:
        description: Timeout in milliseconds to wait for each reply.
        required: false
        default: '5000'

  workflow:
    - ping_the_host:
        do: network.ping
        inputs:
          - host: ${host}
          - ping_count: ${ping_count}
          - timeout: ${timeout}
        publish:
          - return_code
          - return_result
          - packet_loss
        navigate:
          - SUCCESS: ON_SUCCESS
          - FAILURE: ON_FAILURE

    - ON_SUCCESS:
        return: SUCCESS

    - ON_FAILURE:
        return: FAILURE

  outputs:
    - return_code
    - return_result
    - packet_loss

  results:
    - SUCCESS
    - FAILURE