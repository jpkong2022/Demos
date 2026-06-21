namespace: ai
flow:
  name: execute_windows_dir
  workflow:
    - run_dir_command:
        do:
          io.cloudslang.base.cmd.run_command:
            - command: dir  # Execute the 'dir' command
        publish:
          - directory_listing: '${return_result}' # Publish the command output
          - return_code: '${return_code}'        # Publish the return code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - directory_listing: '${directory_listing}' # Output the directory listing
    - return_code: '${return_code}'            # Output the return code
  results:
    - SUCCESS
    - FAILURE
