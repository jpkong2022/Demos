namespace: ai
flow:
  name: delete_o365_user_test
  inputs:
    # Inputs derived from the provided O365 credentials
    - tenant_id:
        default: "z1jfl.onmicrosoft.com"
        required: false # Defaulting based on provided info
    - client_id:
        default: "fdba704b-86b6-4b64-b679-3f6f951216b0"
        required: false # Defaulting based on provided info
    - client_secret:
        default: "xsg8Q~NID1ZpyFc7ZlrMULL0pnutm~vfdaFu0cVf"
        required: false # Defaulting based on provided info
        sensitive: true
    - user_principal_name_to_delete:
        default: "test@z1jfl.onmicrosoft.com" # Hardcoding the user "test" within the tenant
        required: false
    # Optional proxy and TLS settings (good practice)
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true
    - trust_all_roots:
        default: 'false'
        required: false
    - x509_hostname_verifier:
        default: strict
        required: false

  workflow:
    # Step 1: Authenticate to Azure AD / Microsoft Graph API
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
            - data: "${tenant_id}"
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
            - trust_all_roots: "${trust_all_roots}"
            - x509_hostname_verifier: "${x509_hostname_verifier}"
        publish:
          - auth_response_json: '${return_result}'
          - auth_status_code: '${status_code}'
          - auth_exception: '${exception}'
        navigate:
          # Check if request was successful (usually 200 OK)
          - HTTP_200: extract_token # Assuming 200 is success for token request
          - FAILURE: on_failure # Covers connection errors etc.
          # Add other status codes if needed, navigate them to failure or specific handling
          - OTHERWISE: on_failure

    - extract_token:
        do:
          io.cloudslang.base.json.json_path_query:
            - json_object: '${auth_response_json}'
            - json_path: $.access_token
        publish:
          - access_token: '${return_result[1:-1]}' # Removes surrounding quotes if present
        navigate:
          # Check if token extraction worked (json_path_query returns non-empty result)
          - SUCCESS: delete_user # Proceed to delete user if token obtained
          - FAILURE: on_failure # Token not found in response

    # Step 2: Delete the specified user using the obtained token
    - delete_user:
        do:
          # Using generic http_client_request for DELETE method
          io.cloudslang.base.http.http_client_request:
            - url: "${'https://graph.microsoft.com/v1.0/users/%s' % user_principal_name_to_delete}"
            - method: DELETE
            - auth_type: bearer # Use Bearer token authentication
            - token: '${access_token}'
            - proxy_host: "${proxy_host}"
            - proxy_port: "${proxy_port}"
            - proxy_username: "${proxy_username}"
            - proxy_password:
                value: "${proxy_password}"
                sensitive: true
            - trust_all_roots: "${trust_all_roots}"
            - x509_hostname_verifier: "${x509_hostname_verifier}"
            # No body needed for DELETE user operation
        publish:
          - delete_status_code: '${status_code}'
          - delete_response: '${return_result}' # Usually empty for successful DELETE (204)
          - delete_exception: '${exception}'
        navigate:
          # Check for successful deletion (HTTP 204 No Content)
          - HTTP_204: SUCCESS
          # Handle potential errors like User Not Found (HTTP 404)
          - HTTP_404: on_failure # Or specific handling for not found
          # Handle other errors (e.g., permissions - 403, bad request - 400)
          - FAILURE: on_failure # Covers connection errors etc.
          - OTHERWISE: on_failure # Catch-all for other non-success HTTP codes

  outputs:
    - status_code: '${delete_status_code}' # Report the final status code
    - result_message: '${delete_response if delete_status_code == "204" else (delete_exception if delete_exception else "Failed with status code: " + delete_status_code)}' # Provide response or error info

  results:
    - SUCCESS # Reached if delete_user returns 204
    - FAILURE # Reached if any step fails or delete_user returns non-204 status
