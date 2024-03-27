namespace: ai
flow:
  name: reset_password
  inputs:
    - user_id
    - new_password
  workflow:
    - authenticate:
        do:
          office365.auth.authenticate: []
        publish:
          - token
        navigate:
          - FAILURE: FAILURE_AUTH
          - SUCCESS: http_graph_action
    - http_graph_action:
        do:
          office365._tools.http_graph_action:
            - url: '/users/${user_id}'
            - token: '${token}'
            - method: PATCH
            - body: |
                {
                  "passwordProfile" : {
                    "forceChangePasswordNextSignIn": true,
                    "password": "${new_password}"
                  }
                }
        publish:
          - http_status: '${return_result}'
        navigate:
          - FAILURE: FAILURE_PATCH
          - SUCCESS: SUCCESS
  outputs:
    - http_status: '${http_status}'
  results:
    - SUCCESS
    - FAILURE_AUTH
    - FAILURE_PATCH
