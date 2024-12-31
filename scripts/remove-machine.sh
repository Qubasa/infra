
#!/usr/bin/env bash

set -eoux


# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <machine_name>"
    exit 1
fi

# The first argument is the machine name or a pattern to match
MACHINE_NAME=$1

# Execute 'clan secrets list', filter output with 'grep', and iterate over each line
clan secrets list | grep "$MACHINE_NAME" | while read -r line; do
    # Remove the secret using 'clan secrets remove' command
    clan secrets remove "$line"
done

clan secrets users remove "$MACHINE_NAME" || true

rm -r "$GIT_ROOT/vars/per-machine/$MACHINE_NAME" || true
rm -r "$GIT_ROOT/sops/machines/$MACHINE_NAME" || true
rm -r "$GIT_ROOT/machines/$MACHINE_NAME" || true

# remove shared secrets for this machine
find -L ./vars/shared -maxdepth 4 -type l -delete

echo "Done removing machine $MACHINE_NAME"
