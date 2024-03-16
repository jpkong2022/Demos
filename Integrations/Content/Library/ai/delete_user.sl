namespace: ai
flow:
  name: delete_user
  inputs:
    - user_id
  workflow:
    - authenticate:
        do:
          office365.auth.authenticate: []
        publish:
          - token
        navigate:
          - FAILURE: FAILURE_1
          - SUCCESS: http_graph_action
    - http_graph_action:
        do:
          office365._tools.http_graph_action:
            - url: '/users/${user_id}'
            - token: '${token}'
            - method: DELETE
        publish:
          - http_status: '${return_result}'
        navigate:
          - FAILURE: FAILURE_2
          - SUCCESS: SUCCESS
  outputs:
    - http_status: '${http_status}'
  results:
    - SUCCESS
    - FAILURE_1
    - FAILURE_2