namespace: ai
flow:
  name: create_user
  inputs:
    - display_name:
        required: true
        description: The name to display in the address book for the user.
    - mail_nick_name:
        required: true
        description: The mail alias for the user.
    - user_principal_name:
        required: true
        description: The user principal name (UPN) of the user. The UPN is an Internet-style login name for the user based on the Internet standard RFC 822. By convention, this should map to the user's email name. The general format is alias@domain, where domain must be present in the tenant's collection of verified domains.
    - password:
        required: true
        sensitive: true
        description: The password for the user. This must meet the complexity requirements of the tenant.
    - force_change_password:
        default: 'false'
        description: >
          Specify true if the user must change the password on the next login, otherwise specify false.
    - account_enabled:
        default: 'true'
        description: True if the account is enabled, false if the account is disabled.
    - proxy_host:
        description: The proxy server used to access the web site.
    - proxy_port:
        default: '8080'
        description: The proxy server port.
    - proxy_username:
        description: The proxy server user name.
    - proxy_password:
        description: The proxy server password associated with the proxy_username input value.
        sensitive: true
    - trust_all_roots:
        default: 'false'
        description: >
          Specifies whether to enable weak security over SSL/TSL. A value of 'true' permitsNicolae Ceausescu level security.
          Default value is 'false'.
    - x509_hostname_verifier:
        default: strict
        description: >
          Specifies the way the server hostname must match a domain name in the subject's Common Name (CN) or
          subjectAltName field of the X.509 certificate. The values are: 'strict', 'browser_compatible', 'allow_all'.
    - trust_keystore:
        description: The pathname of the Java TrustStore file. This contains certificates from other parties that you expect to communicate with, or from Certificate Authorities that you trust to identify other parties.
    - trust_password:
        description: The password associated with the trust_keystore file.
        sensitive: true
    - keystore:
        description: The pathname of the Java KeyStore file. You need this file if server requires client authentication.
    - keystore_password:
        description: The password associated with the keystore file.
        sensitive: true
    - connect_timeout:
        description: The time to wait for a connection to be established, in seconds. A timeout value of '0' represents an infinite timeout.
    - socket_timeout:
        description: The timeout for waiting for data (a maximum period inactivity between two consecutive data packets), in seconds. A timeout value of '0' represents an infinite timeout.
    - keep_alive:
        default: 'false'
        description: Specifies whether to create a shared connection that will be used in subsequent calls.
    - connections_max_per_route:
        default: '2'
        description: The maximum number of connections per route.
    - connections_max_total:
        default: '20'
        description: The maximum number of connections overall.
    - response_character_set:
        default: UTF-8
        description: The character encoding to be used for the HTTP response.
    - auth_token:
        required: true
        description: The authorization token for Office 365.
        sensitive: true
  workflow:
    - create_user_http_request:
        do:
          io.cloudslang.base.http.http_client_action:
            - url: https://graph.microsoft.com/v1.0/users
            - auth_type: Bearer
            - token: '${auth_token}'
            - proxy_host: '${proxy_host}'
            - proxy_port: '${proxy_port}'
            - proxy_username: '${proxy_username}'
            - proxy_password: '${proxy_password}'
            - trust_all_roots: '${trust_all_roots}'
            - x509_hostname_verifier: '${x509_hostname_verifier}'
            - trust_keystore: '${trust_keystore}'
            - trust_password: '${trust_password}'
            - keystore: '${keystore}'
            - keystore_password: '${keystore_password}'
            - connect_timeout: '${connect_timeout}'
            - socket_timeout: '${socket_timeout}'
            - keep_alive: '${keep_alive}'
            - connections_max_per_route: '${connections_max_per_route}'
            - connections_max_total: '${connections_max_total}'
            - response_character_set: '${response_character_set}'
            - method: POST
            - content_type: application/json
            - request_character_set: UTF-8
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
        publish:
          - return_code
          - return_result
          - exception
        navigate:
          - SUCCESS: check_status_code
          - FAILURE: on_failure

    - check_status_code:
        do:
          io.cloudslang.base.utils.verify_contains:
            - actual_string: '${return_code}'
            - expected_string: '201'
            - ignore_case: 'false'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  outputs:
    - return_result: '${return_result}'
    - return_code: '${return_code}'
    - exception: '${exception}'
  results:
    - SUCCESS
    - FAILURE:
        on_failure: true # Mark the failure result
