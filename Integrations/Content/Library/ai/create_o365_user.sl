namespace: ai

imports:
  office365_ops: io.cloudslang.office365.actions

flow:
  name: create_office365_user
  inputs:
    - username
    - password
    - display_name
    - mail_nickname
    - usage_location: 'US'
    - account_enabled: 'true'
    - force_change_password: 'true'
  workflow:
    - create_user:
        do:
          office365_ops.create_user:
            - userPrincipalName: ${username}
            - displayName: ${display_name}
            - mailNickname: ${mail_nickname}
            - password: ${password}
            - forceChangePasswordNextSignIn: ${force_change_password}
            - accountEnabled: ${account_enabled}
            - usageLocation: ${usage_location}
        publish:
          - user_id
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  outputs:
    - user_id
  results:
    - SUCCESS
    - FAILURE