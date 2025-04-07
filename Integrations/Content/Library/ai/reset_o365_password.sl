namespace: ai
flow:
  name: reset_o365_password
  inputs:
    - user_principal_name:
        required: true
        description: The User Principal Name (email address) of the user whose password needs to be reset.
    - new_password:
        required: true
        sensitive: true
        description: The new password for the user.
    - force_change_password:
        default: 'true'
        description: Specifies whether the user must change the password at the next sign-in. ('true' or 'false')
  workflow:
    - authenticate:
        do:
          # Assuming a standard authentication operation exists
          # Replace with your actual authentication operation if different
          office365.auth.authenticate: []
        publish:
          - token
        navigate:
          - FAILURE: on_failure
          - SUCCESS: http_update_user_password
    - http_update_user_password:
        do:
          # Using the generic HTTP action to call MS Graph API
          office365._tools.http_graph_action:
            - url: ${'/users/' + user_principal_name} # Construct user-specific URL
            - token: '${token}'
            - method: PATCH # Use PATCH to update existing user properties
            - body: 
                ${{
                  "accountEnabled": account_enabled,
                  "displayName": display_name,
                  "mailNickname": mail_nickname,
                  "userPrincipalName": user_principal_name,
                  "passwordProfile": {
                    "forceChangePasswordNextSignIn": force_change_password,
                    "password": initial_password
                  }
                }}
        publish:
          - status_code: '${return_code}'
          - response_body: '${return_result}'
        navigate:
          # Check status code, typically 204 No Content for successful PATCH
          - SUCCESS: ${status_code >= 200 and status_code < 300}
          - FAILURE: on_failure # Any other status code is treated as failure
  outputs:
    - status_code: '${status_code}'
    - response_body: '${response_body}'
  results:
    - FAILURE
    - SUCCESS
