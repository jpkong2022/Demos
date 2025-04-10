namespace: ai
flow:
  name: create_smax_change
  inputs:
    - smax_host:
        required: true
        description: The hostname or IP address of the SMAX instance.
    - smax_tenant_id:
        required: true
        description: The SMAX tenant ID.
    - smax_username:
        required: true
        description: The username for SMAX authentication (integration user recommended).
    - smax_password:
        required: true
        sensitive: true
        description: The password for the SMAX user.
    - change_title:
        required: true
        description: The title/display label for the new change request.
    - change_description:
        required: false
        default: ''
        description: The detailed description of the change request.
    - change_priority:
        required: false
        default: 'Medium' # Example default, adjust based on your SMAX configuration
        description: The priority of the change request (e.g., Low, Medium, High, Critical).
    - change_urgency:
        required: false
        default: 'Medium' # Example default, adjust based on your SMAX configuration
        description: The urgency of the change request (e.g., Low, Medium, High, Critical).
    # Add other relevant inputs like category, service, assigned_group etc. as needed.
    # - change_category:
    # - assigned_group_name:

  workflow:
    - create_change_request:
        do:
          # NOTE: The exact operation path might vary based on your CloudSlang SMAX content pack version.
          # This assumes a generic 'create_record' operation exists. A more specific 'create_change' might be available.
          io.cloudslang.microfocus.smax.entities.create_record:
            - host: ${smax_host}
            - tenant_id: ${smax_tenant_id}
            - username: ${smax_username}
            - password:
                value: ${smax_password}
                sensitive: true
            - entity_type: 'Change' # Specifies the type of record to create
            - data: # JSON string containing the fields for the new change
                # Adjust field names (e.g., DisplayLabel, Description, Priority, Urgency)
                # based on your actual SMAX configuration and API names.
                value: >
                  {
                    "properties": {
                      "DisplayLabel": "${change_title}",
                      "Description": "${change_description}",
                      "Priority": "${change_priority}",
                      "Urgency": "${change_urgency}"
                      # Add other fields here matching your SMAX model, e.g.:
                      # ,"ChangeModel": {"id": "ID_OF_NORMAL_CHANGE_MODEL"}
                      # ,"RegisteredForService": {"id": "ID_OF_SERVICE"}
                      # ,"OwnedByGroup": {"id": "ID_OF_GROUP"}
                    }
                  }
        publish:
          - change_id: ${return_result} # Assuming the operation returns the new record's ID
          - error_message: ${error_message}
          - return_code: ${return_code}
        navigate:
          - SUCCESS: check_result
          - FAILURE: on_failure

    - check_result:
        do:
          io.cloudslang.base.utils.do_nothing: # Placeholder to check return code if needed
            - result: ${return_code}
        navigate:
          - SUCCESS: SUCCESS # Assuming return_code 0 means success from create_record
          - FAILURE: on_failure # Non-zero return_code might indicate API level failure

  outputs:
    - change_id: ${change_id}
    - error_message: ${error_message}
    - return_code: ${return_code}

  results:
    - SUCCESS
    - FAILURE
