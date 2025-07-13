# This script helps clean up stale AppArmor entries and fix the
# "Failed to destroy apparmor namespace" error in Incus

# 1. Variables
PROFILE_DIR="/var/lib/incus/security/apparmor/profiles"
CACHE_DIR="/var/lib/incus/security/apparmor/cache"
PROFILE_NAME="incus-alpine-blank"

# 2. Print error context
echo "Looking for profile: $PROFILE_NAME"

# 3. Check if the profile exists
if [ ! -f "$PROFILE_DIR/$PROFILE_NAME" ]; then
    echo "Profile $PROFILE_NAME not found. Skipping removal."
else
    echo "Removing profile $PROFILE_NAME"
    sudo apparmor_parser -R "$PROFILE_DIR/$PROFILE_NAME"
    sudo rm -f "$PROFILE_DIR/$PROFILE_NAME"
fi

# 4. Clean up cache
if [ -d "$CACHE_DIR" ]; then
    echo "Cleaning up AppArmor cache..."
    sudo find "$CACHE_DIR" -name "*${PROFILE_NAME}*" -exec rm -v {} \;
else
    echo "Cache directory not found."
fi

# 5. Reload AppArmor (optional but recommended)
echo "Reloading AppArmor service..."
sudo systemctl reload apparmor || sudo systemctl restart apparmor

# 6. Retry stopping the container
echo "Retrying stop command..."
incus stop alpine-blank --force