source utils/shell-helpers.sh

# --- run set up file in container --- #
SETUP_FILE=/var/lnamps/project/setup.sh
cecho $_BRIGHT_GREEN "# [CONTAINER] Switching execution to container..."
incus exec $PROJECT_NAME -- bash -c "cd /var/lnamps/project && bash $SETUP_FILE"



