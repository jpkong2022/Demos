namespace: ai
flow:
  name: create_o365_user
  inputs:
    - tenant_id
    - client_id
    - client_secret
    - user_principal_name
    - display_name
    - mail_nickname
    - password
    - force_change_password_on_next_login
    - account_enabled
    - usage_location
    - proxy_host
    - proxy_port
    - proxy_username
    - proxy_password
  workflow:
    # 1. Get OAuth2 Access Token for Microsoft Graph API
    - get_access_token:
        do:
          io.cloudslang.base.http.http_client_action:
            - url: ${'https://login.microsoftonline.com/' + tenant_id + '/oauth2/v2.0/token'}
            - method: POST
            - headers: 'Content-Type: application/x-www-form-urlencoded'
            - form_params: 
                ${{
                  'client_id': client_id,
                  'scope': 'https://graph.microsoft.com/.default',
                  'client_secret': client_secret,
                  'grant_type': 'client_credentials'
                }}
            - proxy_host: ${get('proxy_host', '')}
            - proxy_port: ${get('proxy_port', '8080')}
            - proxy_username: ${get('proxy_username', '')}
            - proxy_password: ${get('proxy_password', '')}
            - trust_all_roots: "true" # Consider security implications
            - x_509_hostname_verifier: "allow_all" # Consider security implications
        publish:
          - access_token: ${return_result.extract_data('$.access_token')}
          - token_status_code: ${status_code}
          - token_error: ${error_message if return_code == -1 else ''}
        navigate:
          - SUCCESS: ${check_token_status}
          - FAILURE: on_failure # Generic failure if HTTP call itself fails

    # 2. Check Token Request Status
    - check_token_status:
        do:
          io.cloudslang.base.utils.equals:
             - first: ${token_status_code}
             - second: "200"
        navigate:
          - SUCCESS: construct_user_payload # Token received successfully
          - FAILURE: TOKEN_FAILURE # Token request returned non-200 status

    # 3. Construct the User Payload JSON Body
    - construct_user_payload:
        do:
          # This step ideally uses a JSON manipulation operation or scripting
          # For simplicity here, we build the string directly. A real scenario
          # might use io.cloudslang.base.json.json_builder or similar.
          io.cloudslang.base.scriptlets.append:
            - value: 
                ${'
                {
                  "accountEnabled": ' + (account_enabled == 'true' ? 'true' : 'false') + ',
                  "displayName": "' + display_name + '",
                  "mailNickname": "' + mail_nickname + '",
                  "userPrincipalName": "' + user_principal_name + '",
                  "usageLocation": ' + (get('usage_location') ? '"' + usage_location + '"' : 'null') + ',
                  "passwordProfile": {
                    "forceChangePasswordNextSignIn": ' + (force_change_password_on_next_login == 'true' ? 'true' : 'false') + ',
                    "password": "' + password + '"
                  }
                }
                '}
        publish:
          - user_payload: ${scriptlet_output}
        navigate:
          - SUCCESS: create_user_api_call
          - FAILURE: on_failure # Should not fail unless scriptlet error

    # 4. Call Microsoft Graph API to Create the User
    - create_user_api_call:
        do:
          io.cloudslang.base.http.http_client_action:
            - url: https://graph.microsoft.com/v1.0/users
            - method: POST
            - headers: ${'Authorization: Bearer ' + access_token + ', Content-Type: application/json'}
            - body: ${user_payload}
            - proxy_host: ${get('proxy_host', '')}
            - proxy_port: ${get('proxy_port', '8080')}
            - proxy_username: ${get('proxy_username', '')}
            - proxy_password: ${get('proxy_password', '')}
            - trust_all_roots: "true" # Consider security implications
            - x_509_hostname_verifier: "allow_all" # Consider security implications
        publish:
          - create_status_code: ${status_code}
          - create_response: ${return_result}
          - create_error: ${error_message if return_code == -1 else ''}
          - user_id: ${return_result.extract_data('$.id') if status_code == '201' else ''}
        navigate:
          - SUCCESS: ${check_create_status}
          - FAILURE: on_failure # Generic failure if HTTP call itself fails

    # 5. Check User Creation Status
    - check_create_status:
        do:
          io.cloudslang.base.utils.equals:
             - first: ${create_status_code}
             - second: "201" # HTTP 201 Created indicates success
        navigate:
          - SUCCESS: on_success
          - FAILURE: CREATE_FAILURE

    # Success Path
    - on_success:
        do:
          io.cloudslang.base.utils.return_success:
            - return_result: ${'Successfully created Office 365 user. User ID: ' + user_id}
        publish:
          - user_id: ${user_id}
        navigate:
          - SUCCESS: SUCCESS

    # Failure Paths
    - TOKEN_FAILURE:
        do:
           io.cloudslang.base.utils.return_failure:
             - return_result: ${'Failed to obtain access token. Status Code: ' + token_status_code + '. Error: ' + token_error + '. Response: ' + get('return_result','')}
        navigate:
          - FAILURE: FAILURE

    - CREATE_FAILURE:
        do:
           io.cloudslang.base.utils.return_failure:
             - return_result: ${'Failed to create Office 365 user. Status Code: ' + create_status_code + '. Error: ' + create_error + '. Response: ' + create_response}
        navigate:
          - FAILURE: FAILURE

    - on_failure: # Generic catch-all for operation execution errors
       do:
          io.cloudslang.base.utils.return_failure:
            - return_result: ${'An unexpected error occurred: ' + error_message}
       navigate:
         - FAILURE: FAILURE

  outputs:
    - user_id: ${user_id}
    - return_code: ${return_code}
    - return_result: ${return_result}
    - exception: ${exception}

  results:
    - SUCCESS
    - FAILURE