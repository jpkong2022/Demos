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
            - url: "${graph_api_url + '/users'}"
            - proxy_host: "${proxy_host if proxy_host is not none else get_sp('proxy_host', '')}"
            - proxy_port: "${proxy_port if proxy_port is not none else get_sp('proxy_port', '8080')}"
            - headers: 
                ${{
                  'Authorization': 'Bearer ' + access_token,
                  'Content-Type': 'application/json'
                }}
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
          - SUCCESS: SUCCESS
          - FAILURE: on_failure # Any other status code is treated as failure
  outputs:
    - status_code: '${status_code}'
    - response_body: '${response_body}'
  results:
    - FAILURE
    - SUCCESS
