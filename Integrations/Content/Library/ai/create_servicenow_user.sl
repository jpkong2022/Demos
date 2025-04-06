# CloudSlang Workflow: Create ServiceNow User
# Namespace: Identifies the scope of this workflow
namespace: ai

# Flow Definition
flow:
  # Name of the workflow
  name: create_servicenow_user

  # Inputs required by the workflow
  inputs:
    - snow_host:
        description: ServiceNow instance hostname or IP address (e.g., myinstance.service-now.com)
        required: true
    - snow_username:
        description: ServiceNow username for authentication with privileges to create users.
        required: true
    - snow_password:
        description: ServiceNow password for authentication.
        required: true
        sensitive: true
    - first_name:
        description: First name of the new user.
        required: true
    - last_name:
        description: Last name of the new user.
        required: true
    - user_name:
        description: The User ID (login name) for the new ServiceNow user.
        required: true
    - email:
        description: Email address for the new user.
        required: true
    - user_password:
        description: Initial password for the new ServiceNow user.
        required: true
        sensitive: true
    - title:
        description: Job title for the new user.
        required: false
    - department:
        description: Department name or sys_id for the new user.
        required: false
    - location:
        description: Location name or sys_id for the new user.
        required: false
    - active:
        description: Whether the user account should be active.
        required: false
        default: 'true' # ServiceNow often expects strings 'true'/'false'
    - locked_out:
        description: Whether the user account should be initially locked out.
        required: false
        default: 'false' # ServiceNow often expects strings 'true'/'false'

  # Workflow Steps (Tasks)
  workflow:
    # Task to create the user using a hypothetical ServiceNow content pack operation
    - CreateUserTask:
        # 'do' specifies the operation to execute.
        # NOTE: The actual operation path depends on the specific ServiceNow Content Pack used.
        # Replace 'io.cloudslang.servicenow.users.create_user' with the correct path.
        do:
          io.cloudslang.servicenow.users.create_user:
            # Map flow inputs to operation inputs
            - host: ${snow_host}
            - username: ${snow_username}
            - password: ${snow_password}
            - first_name: ${first_name}
            - last_name: ${last_name}
            - user_name: ${user_name}
            - email: ${email}
            - user_password: ${user_password}
            - title: ${title}
            - department: ${department}
            - location: ${location}
            - active: ${active}
            - locked_out: ${locked_out}
        # Publish outputs from the operation for potential use later or as flow outputs
        publish:
          - user_sys_id # Assuming the operation returns the sys_id of the created user
          - return_code
          - exception
        # Navigation rules based on the operation's result
        navigate:
          - SUCCESS: SUCCESS # If operation succeeds, flow result is SUCCESS
          - FAILURE: FAILURE # If operation fails, flow result is FAILURE

  # Outputs returned by the workflow
  outputs:
    - user_sys_id:
        description: The unique sys_id of the newly created ServiceNow user.
        value: ${user_sys_id}
    - return_code:
        description: Return code from the create user operation (e.g., 0 for success).
        value: ${return_code}
    - exception:
        description: Any exception message if the operation failed.
        value: ${exception}

  # Possible results (outcomes) of the workflow execution
  results:
    - SUCCESS: ${return_code == '0'} # Define condition for SUCCESS
    - FAILURE # Default failure condition if SUCCESS is not met
