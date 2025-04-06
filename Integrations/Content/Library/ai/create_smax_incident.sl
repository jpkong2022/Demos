namespace: org.example.integrations.smax

imports:
  http: cloudslang/http/http_client
  json: cloudslang/json

flow:
  name: create_smax_incident

  inputs:
    - smax_url:
        description: The base URL of the SMAX instance (e.g., https://smax.example.com)
        required: true
    - smax_tenant_id:
        description: The SMAX tenant ID.
        required: true
    - smax_auth_token:
        description: >
          The authentication token for SMAX API (e.g., LWSSO_COOKIE_KEY value).
          It's recommended to obtain this securely via a separate authentication flow.
        required: true
        sensitive: true
    - incident_title:
        description: The title or short description for the incident (DisplayLabel).
        required: true
    - incident_description:
        description: A detailed description of the incident.
        required: false
        default: ""
    - incident_urgency:
        description: >
          Urgency of the incident (e.g., Low_urgency, Medium_urgency, High_urgency, Critical_urgency).
          Note: The exact value might depend on SMAX configuration (check Administration > Lists).
        required: false
    - incident_impact:
        description: >
          Impact of the incident (e.g., Low_impact, Medium_impact, High_impact, Enterprise_impact).
          Note: The exact value might depend on SMAX configuration (check Administration > Lists).
        required: false
    # Optional Inputs for HTTP Client
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
    - trust_all_roots:
        required: false
        default: "false"
    - connect_timeout:
        required: false
    - socket_timeout:
        required: false

  workflow:
    - build_payload:
        python_action: |
          import json

          incident_properties = {
            "DisplayLabel": incident_title,
            "Description": incident_description
          }

          if incident_urgency:
            incident_properties["Urgency"] = incident_urgency
          if incident_impact:
            incident_properties["Impact"] = incident_impact
          # Add other mandatory or desired fields here (e.g., Service, RequestedByPerson)
          # Note: Fields like Service, Category, RequestedByPerson often require internal SMAX IDs, not just names.
          # Finding these IDs usually requires additional API calls or prior knowledge.
          # For RequestedByPerson, you might need to lookup the Person record ID based on email/UPN first.
          # Example (if you had the Person ID):
          # incident_properties["RequestedByPerson"] = "person_record_id_here"

          payload = {
            "entities": [
              {
                "entity_type": "Incident",
                "properties": incident_properties
              }
            ],
            "operation": "CREATE"
          }

          payload_string = json.dumps(payload)

        publish:
          - incident_payload: payload_string
        navigate:
          - SUCCESS: create_incident_via_api
          - FAILURE: on_failure

    - create_incident_via_api:
        do:
          http.http_client_action:
            - url: ${smax_url + '/rest/' + smax_tenant_id + '/ems/bulk'}
            - method: POST
            - headers: ${'Content-Type:application/json, Cookie:LWSSO_COOKIE_KEY=' + smax_auth_token}
            - body: ${incident_payload}
            # Pass through optional http client inputs
            - proxy_host: ${proxy_host}
            - proxy_port: ${proxy_port}
            - proxy_username: ${proxy_username}
            - proxy_password: ${proxy_password}
            - trust_all_roots: ${trust_all_roots}
            - connect_timeout: ${connect_timeout}
            - socket_timeout: ${socket_timeout}
        publish:
          - status_code: ${return_code == '0' ? http_status_code : '-1'} # Map internal success (0) to HTTP status
          - api_response_body: ${return_result}
          - error_message: ${error_message if return_code != '0' else ''}
        navigate:
          # SMAX Bulk API typically returns 200 OK even for creation
          - SUCCESS: ${status_code == '200'}
          - FAILURE: on_failure # Any other status or error during call

    # Optional: Parse the response to get the created Incident ID
    - parse_response:
        do:
          json.json_path_query:
            - json_object: ${api_response_body}
            # Adjust JSONPath based on actual SMAX response structure for bulk API
            # It usually returns an array of results matching the input entities.
            - json_path: "$.entities[0].properties.Id"
        publish:
          # If parsing fails (e.g., bad path, not JSON), 'result' will be empty or error.
          # The flow might succeed in creating the incident but fail parsing.
          # Consider adding checks around 'result' if needed.
          - incident_id: ${result}
          - raw_api_response: ${api_response_body} # Also publish the raw response
        navigate:
          - SUCCESS: on_success
          - FAILURE: on_failure # Treat parsing failure as overall failure, or create a different outcome

  outputs:
    - incident_id:
        description: The ID of the newly created SMAX incident. May be empty if parsing failed.
        default: ""
    - raw_api_response:
        description: The full response body from the SMAX API call.
        default: ""
    - error_message:
        description: Details of any error encountered during the process.
        default: ""

  results:
    - SUCCESS: ${error_message == ""} # Define success as no errors encountered
    - FAILURE
