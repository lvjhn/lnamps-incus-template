source utils/shell-helpers.sh

# --- update apk
cecho $_BRIGHT_GREEN "# [CONTAINER] Updating apk package manager..."
incus exec $PROJECT_NAME -- apk update

# --- add bash first to enable sourcing this script
cecho $_BRIGHT_GREEN "# [CONTAINER] Installing bash..."
incus exec $PROJECT_NAME -- apk add bash 

# --- run this script in the container
INSTALLER_FILE=/var/lnamps/project/utils/install-base-tools.sh
cecho $_BRIGHT_GREEN "# [CONTAINER] Switching execution to container..."
incus exec $PROJECT_NAME -- bash -c "bash $INSTALLER_FILE"



