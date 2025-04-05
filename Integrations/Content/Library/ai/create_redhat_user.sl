namespace: ai

imports:
  ssh: io.cloudslang.base.remote

flow:
  name: create_redhat_user

  inputs:
    # Target server details
    - hostname:
        description: IP address or hostname of the target Red Hat server.
        required: true
    - port:
        description: SSH port on the target server.
        default: 22
        required: false

    # Credentials to connect TO the server (must have sudo privileges)
    - ssh_username:
        description: Username for SSH connection (e.g., 'admin', 'ec2-user'). Needs sudo rights.
        required: true
    - ssh_password:
        description: Password for the ssh_username. Use ssh_private_key for key-based auth.
        required: false
        sensitive: true
    - ssh_private_key:
        description: Optional. String containing the private key content or path to the private key file
        required: false
        sensitive: true
    - ssh_passphrase:
        description: Optional. Passphrase for the private key if it's encrypted.
        required: false
        sensitive: true

    # New user details
    - new_username:
        description: The username for the new Linux user to be created.
        required: true
    - new_password:
        description: The password for the new user. Will be set using 'chpasswd'.
        required: true
        sensitive: true
    - shell:
        description: The login shell for the new user.
        default: /bin/bash
        required: false
    - create_home:
        description: Whether to create the home directory for the new user (-m option for useradd).
        default: 'true'
        required: false
    - home_base_dir:
        description: Optional. Specify a base directory for the home folder (e.g., /users instead of /home).
        required: false
    - user_groups:
        description: Optional. Comma-separated list of supplementary groups to add the user to.
        required: false
    - user_comment:
        description: Optional. GECOS field / comment for the user.
        required: false

    # Sudo details (if ssh_username is not root)
    - use_sudo:
        description: Set to true if the ssh_username needs to use sudo to execute commands.
        default: 'true'
        required: false
    - sudo_password:
        description: The sudo password for the ssh_username, if required and different from ssh_password.
        required: false
        sensitive: true

  workflow:
    # 1. Construct the useradd command
    - build_useradd_command:
        do:
          io.cloudslang.base.utils.python_script: # Using a scriptlet for robust command building
            script: |
              import shlex

              command_parts = []
              if use_sudo == 'true' or str(use_sudo).lower() == 'true':
                  command_parts.append('sudo')

              command_parts.append('useradd')

              if create_home == 'true' or str(create_home).lower() == 'true':
                  command_parts.append('-m') # Create home directory

              if home_base_dir:
                  command_parts.extend(['-b', home_base_dir])

              if shell:
                  command_parts.extend(['-s', shell])

              if user_groups:
                  command_parts.extend(['-G', user_groups]) # Add supplementary groups

              if user_comment:
                  # Quote the comment properly
                  command_parts.extend(['-c', shlex.quote(user_comment)])

              command_parts.append(new_username) # The new username itself

              # Assign the final command string to an output variable
              script_output = ' '.join(command_parts)

        publish:
          - useradd_command
        navigate:
          - SUCCESS: create_user
          - FAILURE: on_failure # Should not fail unless inputs are wrong

    # 2. Execute the useradd command remotely
    - create_user:
        do:
          ssh.ssh_command:
            host: ${hostname}
            port: ${port}
            username: ${ssh_username}
            password: ${ssh_password}
            private_key_file: ${ssh_private_key}
            passphrase: ${ssh_passphrase}
            command: ${useradd_command}
            pty: ${use_sudo} # PTY often needed for sudo
            sudo_password: ${sudo_password if use_sudo == 'true' else ''} # Pass sudo password if needed
            timeout: '60000' # 60 seconds timeout
        publish:
          - useradd_stdout: ${stdOut}
          - useradd_stderr: ${stdErr}
          - useradd_return_code: ${returnCode}
        navigate:
          - SUCCESS: check_useradd_result
          - FAILURE: on_failure # SSH connection or execution failure

    # 3. Check if useradd succeeded
    - check_useradd_result:
        do:
          io.cloudslang.base.utils.python_script:
              script: |
                # Check if returnCode is 0 (success)
                if returnCode == '0':
                  script_output = 'success'
                else:
                  script_output = 'failure'
              returnCode: ${useradd_return_code} # Pass the return code into the script
        publish:
          - useradd_result: ${script_output}
        navigate:
          - SUCCESS:
              # Decide next step based on the python script's output
              - build_chpasswd_command: ${useradd_result == 'success'}
              - on_failure: ${useradd_result == 'failure'}
          - FAILURE: on_failure # Script execution failure

    # 4. Build the password setting command (using chpasswd for non-interactivity)
    - build_chpasswd_command:
        do:
          io.cloudslang.base.utils.python_script:
            script: |
              # Prepare the input for chpasswd: "username:password"
              # Ensure proper escaping/quoting if password contains special chars, though echo usually handles it ok.
              # Using single quotes around the echo string is generally safer.
              chpasswd_input = "'{}:{}'".format(new_username, new_password)
              command = "echo {} | ".format(chpasswd_input)
              if use_sudo == 'true' or str(use_sudo).lower() == 'true':
                  command += "sudo "
              command += "chpasswd"
              script_output = command
        publish:
          - chpasswd_command
        navigate:
          - SUCCESS: set_password
          - FAILURE: on_failure

    # 5. Set the user's password
    - set_password:
        do:
          ssh.ssh_command:
            host: ${hostname}
            port: ${port}
            username: ${ssh_username}
            password: ${ssh_password}
            private_key_file: ${ssh_private_key}
            passphrase: ${ssh_passphrase}
            command: ${chpasswd_command}
            pty: ${use_sudo} # PTY might be needed for sudo piping
            sudo_password: ${sudo_password if use_sudo == 'true' else ''}
            timeout: '60000' # 60 seconds timeout
        publish:
          - passwd_stdout: ${stdOut}
          - passwd_stderr: ${stdErr}
          - passwd_return_code: ${returnCode}
        navigate:
          - SUCCESS: check_passwd_result
          - FAILURE: on_failure

    # 6. Check password setting result
    - check_passwd_result:
      do:
        io.cloudslang.base.utils.python_script:
            script: |
              if returnCode == '0':
                script_output = 'success'
              else:
                script_output = 'failure'
            returnCode: ${passwd_return_code}
      publish:
        - passwd_result: ${script_output}
      navigate:
        - SUCCESS:
            - finalize_success: ${passwd_result == 'success'}
            - on_failure: ${passwd_result == 'failure'}
        - FAILURE: on_failure

    # Success path termination
    - finalize_success:
        do:
          io.cloudslang.base.utils.return_response:
              response: ${'User ' + new_username + ' created successfully on ' + hostname}
        navigate:
          - SUCCESS: SUCCESS # Final flow success

    # Failure path termination
    - on_failure:
        do:
          io.cloudslang.base.utils.return_response:
              response: ${'Failed to create user ' + new_username + '. useradd_rc=' + str(useradd_return_code) + ', passwd_rc=' + str(passwd_return_code) + ', useradd_stderr=' + str(useradd_stderr) + ', passwd_stderr=' + str(passwd_stderr)}
        navigate:
          - SUCCESS: FAILURE # Final flow failure

  outputs:
    - result_message: ${response} # Comes from return_response ops
    - useradd_rc: ${useradd_return_code}
    - passwd_rc: ${passwd_return_code}
    - useradd_error: ${useradd_stderr}
    - passwd_error: ${passwd_stderr}

  results:
    - SUCCESS: ${response.find('successfully') != -1} # Check if success message exists
    - FAILURE
