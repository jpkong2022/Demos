namespace: ai
flow:
  name: delete_user4
  inputs:
    - user_id
  workflow:
    - authenticate:
        do:
          office365.auth.authenticate: []
        publish:
          - token
        navigate:
          - FAILURE: FAILURE
          - SUCCESS: http_graph_action
    - http_graph_action:
        do:
          office365._tools.http_graph_action:
            - url: "/users/${user_id}"
            - token: "${token}"
            - method: DELETE
        publish:
          - http_status: "${return_result}"
        navigate:
          - FAILURE: FAILURE
          - SUCCESS: SUCCESS
  results:
    - FAILURE
    - SUCCESS


