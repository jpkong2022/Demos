namespace:ai
imports:
  network: io.cloudslang.base.network
flow:
  name: ping_server
  inputs:
    - host
    - ping_count
    - timeout
  workflow:
    - ping_the_host:
        do:
          network.ping:
            - host: ${host}
            - ping_count: ${ping_count}
            - timeout: ${timeout}
        publish:
          - return_code: '${return_code}'
          - return_result: '${return_result}'
          - packet_loss: '${packet_loss}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
    - success_step:
        navigate:
          - SUCCESS: SUCCESS
    - failure_step:
        navigate:
          - SUCCESS: FAILURE
  outputs:
    - return_code: '${return_code}'
    - return_result: '${return_result}'
    - packet_loss: '${packet_loss}'
  results:
    - SUCCESS
    - FAILURE