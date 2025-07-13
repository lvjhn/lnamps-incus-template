source .env
source utils/shell-helpers.sh

set -e

# --- CLEAR INSTANCE --- # 
function clear_instance() {
    if has_instance $PROJECT_NAME; then
        cecho $_BRIGHT_GREEN "# [HOST] Instance found, deleting..."
        if is_instance_running; then
            cecho $_BRIGHT_GREEN "# [HOST] Instance is running, stopping it..." 
            incus stop $PROJECT_NAME 
        else 
            cecho $_BRIGHT_YELLOW "# [HOST] Instance is already stopped." 
        fi
        incus delete $PROJECT_NAME
    else
        cecho $_BRIGHT_GREEN "# [HOST] Instance not found, skipping..."
    fi
}

# --- CREATE INSTANCE --- # 
function create_instance() {
    if ! has_instance $PROJECT_NAME; then 
        cecho $_BRIGHT_GREEN "# [HOST] Creating instance..."
        incus init images:alpine/$ALPINE_VERSION $PROJECT_NAME 
    else 
        cecho $_BRIGHT_GREEN "# [HOST] Instance exists already, must not exist."
    fi
}

# --- CONFIGURE INSTANCE --- # 
function configure_instance() {
    if ! has_instance $PROJECT_NAME; then 
        cecho $_BRIGHT_RED "# [HOST] Instance does not exist, cannot continue..."
    fi 

    # --- setup storage --- # 
    setup_storage 
    
    # --- setup network --- # 
    setup_network 
}

# --- SET UP STORAGE --- # 
function setup_storage() {
    cecho $_BRIGHT_GREEN "# [HOST] Setting up instance storage..."

    if [ ! -d /opt/lnamps ]; then 
        sudo mkdir -p /opt/lnamps
        sudo chmod 777 -R /opt/lnamps
    fi

    incus config device add $PROJECT_NAME \
        project disk \
        source=$(pwd) \
        path=/var/lnamps/project/ \
        shift=true
}

# --- SET UP NETWORK --- # 
function setup_network() {
    cecho $_BRIGHT_GREEN "# [HOST] Setting up instance network..."

    # --- create bridge network --- # 
    CREATE_NETWORK=${CREATE_NETWORK:-"true"}
    BRIDGE_NAME=${NETWORK_NAME:-lnamps}
    BRIDGE_IP=${NETWORK_IP:-"10.10.10.1"}
    BRIDGE_DOMAIN=${NETWORK_DOMAIN:-.lnamps}
    
    if [ "$CREATE_NETWORK" = "true" ]; then
        if ! has_network $BRIDGE_NAME ; then
            cecho $_BRIGHT_GREEN "# [HOST] Creating network bridge: $BRIDGE_NAME."
            incus network create "$BRIDGE_NAME"
            incus network set "$BRIDGE_NAME" ipv4.address=$BRIDGE_IP/24
            incus network set "$BRIDGE_NAME" ipv4.nat=true
            incus network set "$BRIDGE_NAME" ipv6.address=none
            incus network set "$BRIDGE_NAME" dns.mode=managed
            incus network set "$BRIDGE_NAME" dns.domain=.$BRIDGE_DOMAIN
        else
            cecho $_BRIGHT_YELLOW "# [HOST] Network bridge $BRIDGE_NAME already exists."
        fi
    else
        cecho $_BRIGHT_YELLOW "# [HOST] Skipping network creation..."
    fi

    cecho $_BRIGHT_BLUE "# [HOST] Connecting to network bridge $BRIDGE_NAME."
    incus config device add $PROJECT_NAME eth0 nic network=$BRIDGE_NAME name=eth0
}   


# --- START CONTAINER --- # 
function start_container() {
    cecho $_BRIGHT_GREEN "# [HOST] Starting container..."
    incus start $PROJECT_NAME
}


# --- FLOW --- #
function flow() {
    clear_instance
    create_instance
    configure_instance
    start_container
}

flow