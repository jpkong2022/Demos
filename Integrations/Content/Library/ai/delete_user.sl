namespace: ai
flow:
  name: delete_user
  inputs:
    - user_principal_name:
        required: true
        description: The User Principal Name (e.g., user@domain.com) or the user object ID of the user to delete.
  workflow:
    - authenticate:
        do:
          office365.auth.authenticate: []
        publish:
          - token
        navigate:
          - FAILURE: on_failure
          - SUCCESS: http_graph_action_delete
    - http_graph_action_delete:
        do:
          office365._tools.http_graph_action:
            - url: '/users/${user_principal_name}'  # Construct URL with the user identifier
            - token: '${token}'
            - method: DELETE                 # Use DELETE method
            # No body is typically needed for a DELETE request
        publish:
          - delete_response: '${return_result}' # Publish the result/status from the HTTP action
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
  outputs:
    - delete_response: '${delete_response}'
  results:
    - FAILURE
    - SUCCESS
