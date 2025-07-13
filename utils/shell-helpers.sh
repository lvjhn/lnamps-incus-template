#!/bin/bash

if [ -f .env ]; then 
    source .env
fi

_BLACK=30
_RED=31
_GREEN=32
_YELLOW=33
_BLUE=34
_MAGENTA=35
_CYAN=36
_WHITE=37
_BRIGHT_BLACK=90 
_BRIGHT_RED=91
_BRIGHT_GREEN=92
_BRIGHT_YELLOW=93
_BRIGHT_BLUE=94
_BRIGHT_MAGENTA=95
_BRIGHT_CYAN=96
_BRIGHT_WHITE=97

# --- COLORED OUTPUT --- #
function cecho() {
  local color_code="$1"
  local message="$2"
  echo -e "\e[${color_code}m${message}\e[0m"
}

# --- FIND AND REPLACE STRINGS IN FILE --- #
function find_and_replace() {
    HAYSTACK=$1
    NEEDLE=$2
    REPLACE=$3
    sed -i "s|^$NEEDLE|$REPLACE|" "$HAYSTACK"
}

# --- INSERT AFTER LINE --- #
function insert_after_line() {
    FILE=$1
    MATCH=$2
    INSERT=$3
    sed -i "/${MATCH}/a ${INSERT}" "$FILE"
}

# --- FIND IN FILE --- #
function find_in_file() {
    HAYSTACK=$1
    NEEDLE=$2
    if grep -q "^$NEEDLE" "$HAYSTACK"; then
        return 0
    else
        return 1
    fi
}




# --- CHECK IF INCUS HAS INSTANCE --- # 
function has_instance() {
    INSTANCE_NAME=$1
    if incus list --format csv --columns n 2>/dev/null | grep -Fxq "$INSTANCE_NAME"; then
        return 0
    else
        return 1
    fi
}


# --- CHECK IF INCUS HAS NETWORK --- #
function has_network() {
    BRIDGE_NAME=$1
    if incus network show "$BRIDGE_NAME" &>/dev/null; then
        return 0  # true: network exists
    else
        return 1  # false: network does not exist
    fi
}


# --- CHECK IF INCUS INSTANCE IS RUNNING --- #
function is_instance_running() {
    STATE=$(incus list "$PROJECT_NAME" --format csv -c s 2>/dev/null)

    if [ "$STATE" = "RUNNING" ]; then
        return 0  # true: instance is running
    else
        return 1  # false: instance is not running or doesn't exist
    fi
}

# --- WAIT FOR NETWORK --- #
function wait_for_network() {
    cecho $_BRIGHT_GREEN "# Waiting for container to get network..."

    for i in {1..10}; do
        if incus exec $PROJECT_NAME -- sh -c "ip route | grep default" >/dev/null 2>&1; then
            cecho $_BRIGHT_GREEN "# Container has a default route — network is up!"
            return 0
        fi
        sleep 1
    done

    cecho $_BRIGHT_RED "# Timeout waiting for network in container."
    exit 1
}

# --- LOG IN AS USER --- # 
function login_as_user() {
    _UID=$(incus exec "$PROJECT_NAME" -- id -u $CONTAINER_USER)

    # --- execute a shell in the container
    incus exec $PROJECT_NAME \
        --user $_UID \
        -- \
        bash -c "$1"
}

# --- GETS THE USER ID OF THE USER --- #
function user_id() {
    echo $(incus exec "$PROJECT_NAME" -- id -u $CONTAINER_USER)
}

function root_id() {
    echo $(incus exec "$PROJECT_NAME" -- id -u root)
}