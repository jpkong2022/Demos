namespace: ai
flow:
  name: create_user
  inputs:
    - display_name:
        required: true
        description: The name displayed in the address book for the user.
    - mail_nick_name:
        required: true
        description: The mail alias for the user.
    - user_principal_name:
        required: true
        description: The user principal name (UPN) of the user (e.g., AdeleV@contoso.com).
    - password:
        required: true
        sensitive: true
        description: The password for the user. It must meet complexity requirements.
    - force_change_password:
        default: 'true'
        description: If true, the user must change the password on their next sign-in.
    - account_enabled:
        default: 'true'
        description: If true, the account is enabled; otherwise, false.
    - auth_token:
        required: true
        sensitive: true
        description: The authentication token (e.g., Bearer token) for Microsoft Graph API.

  workflow:
    - call_graph_api:
        do:
          # Assuming a generic http_client operation exists.
          # Replace 'cloudslang.base.http.http_client' with the actual path
          # to your standard HTTP client operation if different.
          # Or, if you have a specific Graph API operation like the example, use that.
          # Using a generic one here for broader applicability.
          cloudslang.base.http.http_client:
            - url: "https://graph.microsoft.com/v1.0/users"
            - method: "POST"
            - auth_type: "token"
            - auth_token: '${auth_token}' # Use the input token directly
            - headers: "Content-Type:application/json"
            - body: |-
                ${'''
                {
                  "accountEnabled": %s,
                  "displayName": "%s",
                  "mailNickname": "%s",
                  "userPrincipalName": "%s",
                  "passwordProfile" : {
                    "forceChangePasswordNextSignIn": %s,
                    "password": "%s"
                  }
                }
                ''' % (account_enabled, display_name, mail_nick_name, user_principal_name, force_change_password, password)}
            - return_ Mf Response: true # Ensure the full response object is returned
        publish:
          - status_code: '${return_code}' # Standard output for http_client
          - user_data: '${return_result}' # Standard output for http_client response body
          - error_message: '${error_message}' # Standard output on failure
        navigate:
          # Assuming return_code 201 means success for user creation
          - SUCCESS: ${return_code == '201' ? 'SUCCESS' : 'CHECK_ERROR'}
          - FAILURE: FAILURE # Direct failure of the HTTP operation

    - CHECK_ERROR:
        do:
          cloudslang.base.utils.equals:
            - first: '${status_code.startswith("2")}' # Check if status is 2xx (e.g., 200 OK, though 201 Created is expected)
            - second: 'false'
        navigate:
          - SUCCESS: FAILURE # If status code doesn't start with 2, it's an API error -> FAILURE
          - FAILURE: SUCCESS # If status code starts with 2 but wasn't 201, maybe treat as success? Or add more specific handling. Assuming SUCCESS here if it's 2xx but not 201. Review based on API behavior.

  outputs:
    - status_code: '${status_code}'
    - user_data: '${user_data}'
    - error_message: '${error_message}'

  results:
    - FAILURE
    - SUCCESS
