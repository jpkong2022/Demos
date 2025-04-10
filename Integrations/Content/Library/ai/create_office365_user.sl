namespace: ai
flow:
  name: create_office365_user
  inputs:
    - client_id:
        required: true
    - client_secret:
        required: true
        sensitive: true
    - tenant: # e.g., yourtenant.onmicrosoft.com or the Tenant ID guid
        required: true
    # User details inputs
    - displayName:
        required: true
    - mailNickname:
        required: true
    - userPrincipalName: # e.g., user@yourtenant.onmicrosoft.com
        required: true
    - password:
        required: true
        sensitive: true
    - accountEnabled:
        default: "true" # Defaulting to true, can be overridden
    - forceChangePasswordNextSignIn:
        default: "false" # Defaulting to false, can be overridden
    # Optional Proxy Inputs
    - proxy_host:
        required: false
    - proxy_port:
        required: false
        default: "8080"
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true

  workflow:
    # ----------------------------------------------------------------------
    # Step 1: Authenticate to get the Bearer Token
    # (Reusing logic similar to the provided example)
    # ----------------------------------------------------------------------
    - encode_client_id:
        do:
          io.cloudslang.base.http.url_encoder:
            - data: "${client_id}"
        publish:
          - client_id_q: '${result}'
        navigate:
          - SUCCESS: encode_client_secret
          - FAILURE: on_failure

    - encode_client_secret:
        do:
          io.cloudslang.base.http.url_encoder:
            - data: "${client_secret}"
        publish:
          - client_secret_q: '${result}'
        navigate:
          - SUCCESS: encode_tenant
          - FAILURE: on_failure

    - encode_tenant:
        do:
          io.cloudslang.base.http.url_encoder:
            - data: "${tenant}"
        publish:
          - tenant_q: '${result}'
        navigate:
          - SUCCESS: get_auth_token
          - FAILURE: on_failure

    - get_auth_token:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'https://login.microsoftonline.com/%s/oauth2/v2.0/token' % tenant_q}"
            - proxy_host: "${proxy_host}"
            - proxy_port: "${proxy_port}"
            - proxy_username: "${proxy_username}"
            - proxy_password:
                value: "${proxy_password}"
                sensitive: true
            - body: "${'client_id=%s&client_secret=%s&scope=https%%3A%%2F%%2Fgraph.microsoft.com%%2F.default&grant_type=client_credentials' % (client_id_q, client_secret_q)}"
            - content_type: application/x-www-form-urlencoded
        publish:
          - auth_response_json: '${return_result}'
          - auth_status_code: '${status_code}'
        navigate:
          - SUCCESS: check_auth_status
          - FAILURE: on_failure

    - check_auth_status:
        do:
            io.cloudslang.base.utils.equals:
              - first: '${auth_status_code}'
              - second: '200'
        navigate:
          - SUCCESS: get_token_from_response # Matched, proceed to extract token
          - FAILURE: on_failure # Did not match 200, fail the flow

    - get_token_from_response:
        do:
          io.cloudslang.base.json.json_path_query:
            - json_object: '${auth_response_json}'
            - json_path: $.access_token
        publish:
          - access_token: '${return_result[1:-1]}' # Remove surrounding quotes if any
        navigate:
          - SUCCESS: create_user_request
          - FAILURE: on_failure

    # ----------------------------------------------------------------------
    # Step 2: Create the User using Microsoft Graph API
    # ----------------------------------------------------------------------
    - create_user_request:
        do:
          # Using http_client_action for more control over headers/auth
          io.cloudslang.base.http.http_client_action:
            - method: POST
            - url: "https://graph.microsoft.com/v1.0/users"
            - proxy_host: "${proxy_host}"
            - proxy_port: "${proxy_port}"
            - proxy_username: "${proxy_username}"
            - proxy_password:
                value: "${proxy_password}"
                sensitive: true
            - auth_type: bearer
            - auth_token:
                value: "${access_token}"
                sensitive: true
            - content_type: application/json
            # Construct the JSON body for user creation
            - body: >
                {
                  "accountEnabled": ${accountEnabled},
                  "displayName": "${displayName}",
                  "mailNickname": "${mailNickname}",
                  "userPrincipalName": "${userPrincipalName}",
                  "passwordProfile": {
                    "forceChangePasswordNextSignIn": ${forceChangePasswordNextSignIn},
                    "password": "${password}"
                  }
                }
        publish:
          - create_user_response: '${return_result}'
          - status_code: '${status_code}'
        navigate:
          - SUCCESS: check_create_status
          - FAILURE: on_failure

    # ----------------------------------------------------------------------
    # Step 3: Check the result of the user creation request
    # ----------------------------------------------------------------------
    - check_create_status:
        do:
            io.cloudslang.base.utils.equals:
              - first: '${status_code}'
              # 201 Created is the expected success code for user creation
              - second: '201'
        navigate:
          - SUCCESS: SUCCESS # User created successfully
          - FAILURE: on_failure # User creation failed (wrong status code)

  outputs:
    - status_code: '${status_code}'
    - create_user_response: '${create_user_response}'
    # You might want to parse user_id from create_user_response if needed
    # - user_id: # Requires another json_path_query step on create_user_response looking for $.id

  results:
    - SUCCESS
    - FAILURE
