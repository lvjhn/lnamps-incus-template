# 
# BASE TOOLS INSTALLER 
# 
source /var/lnamps/project/.env
source /var/lnamps/project/utils/shell-helpers.sh 

set -e 

cecho $_BRIGHT_GREEN "# [CONTAINER] Installing base tools..."

# --- INSTALL SUDO --- # 
function install_sudo() {
    echo 
    rm -rf /home/$CONTAINER_USER

    cecho $_BRIGHT_BLUE "# [CONTAINER] INSTALLING [sudo]..."
    apk add sudo=$SUDO_VERSION

    cecho $_BRIGHT_GREEN "# [CONTAINER] Creating user with name $CONTAINER_USER..."
    if id "$CONTAINER_USER" &>/dev/null; then
        deluser $CONTAINER_USER
    else
        :
    fi
    adduser -D $CONTAINER_USER
    
    cecho $_BRIGHT_GREEN "# [CONTAINER] Adding user [$CONTAINER_USER] to wheel group..."
    adduser $CONTAINER_USER wheel

    cecho $_BRIGHT_GREEN "# [CONTAINER] Configuring wheel group..."
    find_and_replace /etc/sudoers \
        "# %wheel ALL=(ALL:ALL) ALL" \
        "%wheel ALL=(ALL:ALL) ALL"

    cecho $_BRIGHT_GREEN "# [CONTAINER] Configuring user password..."
    echo "$CONTAINER_USER:$CONTAINER_PASSWORD" | chpasswd

    cecho $_BRIGHT_GREEN "# [CONTAINER] Configuring root password..."
    echo "root:$CONTAINER_ROOT_PASSWORD" | chpasswd

    cecho $_BRIGHT_GREEN "# [CONTAINER] Linking project folder ..."
    ln -s /var/lnamps/project /home/$CONTAINER_USER/project

    echo 
}


# --- INSTALL MICRO --- # 
function install_micro() {
    echo 

    cecho $_BRIGHT_BLUE "# [CONTAINER] INSTALLING [micro]..."
    apk add micro=$MICRO_VERSION

    echo 
}

# --- INSTALL NANO --- # 
function install_nano() {
    echo 

    cecho $_BRIGHT_BLUE "# [CONTAINER] INSTALLING [nano]..."
    apk add nano=$NANO_VERSION
    
    echo 
}

# --- INSTALL CURL --- # 
function install_curl() {
    echo 

    cecho $_BRIGHT_BLUE "# [CONTAINER] INSTALLING [curl]..."
    apk add curl=$CURL_VERSION
    
    echo 
}

# --- FLOW --- #
install_sudo
install_micro
install_nano
install_curl

source /home/$CONTAINER_USER/project/setup.sh


