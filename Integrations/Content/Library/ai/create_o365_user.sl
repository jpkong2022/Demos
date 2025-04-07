namespace: ai
flow:
  name: create_o365_user
  inputs:
    - tenant_id:
        required: true
        description: The Azure AD tenant ID (e.g., yourdomain.onmicrosoft.com or GUID).
    - client_id:
        required: true
        description: The Application (client) ID registered in Azure AD with permissions to create users.
    - client_secret:
        required: true
        sensitive: true
        description: The client secret for the registered application.
    - display_name:
        required: true
        description: The display name for the new user (e.g., 'Adele Vance').
    - user_principal_name:
        required: true
        description: The user principal name (UPN) for the new user (e.g., 'AdeleV@yourdomain.onmicrosoft.com'). Must be unique within the tenant.
    - mail_nickname:
        required: true
        description: The mail nickname for the new user (used to derive the primary email address, e.g., 'AdeleV').
    - initial_password:
        required: true
        sensitive: true
        description: The initial password for the user. Must meet tenant password policies.
    - force_change_password:
        default: true
        description: If true, the user must change their password on the next sign-in.
    - account_enabled:
        default: true
        description: If true, the account is enabled. If false, the account is created disabled.
    - graph_api_url:
        default: 'https://graph.microsoft.com/v1.0'
        description: The base URL for the Microsoft Graph API.
    - login_url_base:
        default: 'https://login.microsoftonline.com'
        description: The base URL for Azure AD login/token endpoint.
    - proxy_host:
        required: false
        description: Optional proxy host.
    - proxy_port:
        required: false
        default: '8080'
        description: Optional proxy port.

  workflow:
    - get_auth_token:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${login_url_base + '/' + tenant_id + '/oauth2/v2.0/token'}"
            - proxy_host: "${proxy_host if proxy_host is not none else get_sp('proxy_host', '')}"
            - proxy_port: "${proxy_port if proxy_port is not none else get_sp('proxy_port', '8080')}"
            - form_params_are_urlencoded: 'true' # Required for application/x-www-form-urlencoded
            - form_params: >
                ${{
                  'client_id': client_id,
                  'scope': 'https://graph.microsoft.com/.default',
                  'client_secret': client_secret,
                  'grant_type': 'client_credentials'
                }}
            - content_type: 'application/x-www-form-urlencoded'
        publish:
          - token_response: '${return_result}'
          - status_code_token: '${status_code}'
        navigate:
          - SUCCESS:
              # Check if token request was successful (status code 2xx)
              if: "${status_code_token >= '200' and status_code_token < '300'}"
              do: extract_token
          - FAILURE: on_failure # Handle non-2xx status codes from token endpoint

    - extract_token:
        do:
          io.cloudslang.base.json.json_path_query:
            - json_object: '${token_response}'
            - json_path: '$.access_token'
        publish:
          - access_token: '${return_result}'
        navigate:
          - SUCCESS: create_user_request
          - FAILURE: on_failure # Handle JSON parsing failure

    - create_user_request:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${graph_api_url + '/users'}"
            - proxy_host: "${proxy_host if proxy_host is not none else get_sp('proxy_host', '')}"
            - proxy_port: "${proxy_port if proxy_port is not none else get_sp('proxy_port', '8080')}"
            - headers: >
                ${{
                  'Authorization': 'Bearer ' + access_token,
                  'Content-Type': 'application/json'
                }}
            - body: >
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
            - content_type: 'application/json' # Ensure body is treated as JSON
        publish:
          - user_creation_response: '${return_result}'
          - status_code_user: '${status_code}'
          - error_message_user: '${error_message}'
        navigate:
          - SUCCESS:
              # Check if user creation was successful (status code 201 Created)
              if: "${status_code_user == '201'}"
              do: SUCCESS
          - FAILURE: on_failure # Handle non-201 status codes

  outputs:
    - user_creation_response: >
        ${{
          # Return the full response on success, or an error structure on failure
          user_creation_response if status_code_user == '201' else {
            'error': 'Failed to create user',
            'status_code': status_code_user,
            'details': error_message_user if error_message_user is not none else user_creation_response
          }
        }}
    - status_code: '${status_code_user if status_code_user is not none else status_code_token}' # Return the most relevant status code

  results:
    - SUCCESS
    - FAILURE
