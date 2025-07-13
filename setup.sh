if [ -f .env ]; then 
  source .env
fi 

if [ -f utils/shell-helper.sh ]; then 
  source utils/shell-helpers.sh
fi


# --- INSTALLATION SCRIPTS --- # 
function install_python() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [python3 and pip]"
  apk add python3=3.12.11-r0 py3-pip=25.1.1-r0
  echo
}

function install_nodejs() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [nodejs and npm]"
  apk add nodejs=$NODE_VERSION npm=$NPM_VERSION
  echo 
}

function install_php() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [php]"
  apk add php$PHP_VERSION 
  apk add \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-ctype \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-dom \
    php$PHP_VERSION-fileinfo \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-mysqli \
    php$PHP_VERSION-openssl \
    php$PHP_VERSION-pdo \
    php$PHP_VERSION-pdo_mysql \
    php$PHP_VERSION-simplexml \
    php$PHP_VERSION-tokenizer \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-xmlwriter \
    php$PHP_VERSION-phar \
    php$PHP_VERSION-session \
    php$PHP_VERSION-json \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-opcache \
    php$PHP_VERSION-zlib \
    php$PHP_VERSION-sqlite3 \
    php$PHP_VERSION-pdo_sqlite \
    php$PHP_VERSION-pgsql \
    php$PHP_VERSION-pdo_pgsql \
    php$PHP_VERSION-posix \
    php$PHP_VERSION-exif \
    php$PHP_VERSION-pcntl 

  rm -rf /usr/bin/php
  sudo ln -s $(which php$PHP_VERSION) /usr/bin/php

  echo
}

function install_composer() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [composer]"
  php84 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php84 -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
  php84 composer-setup.php --version=$COMPOSER_VERSION
  php84 -r "unlink('composer-setup.php');"
  mv composer.phar /usr/bin/composer
}

function install_postgresql() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [postgresql]"
  apk add postgresql$POSTGRESQL_VERSION
  echo
}

function install_adminer() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [adminer]"

  INSTALL_DIR=/opt/adminer
  DL_LINK=https://github.com/vrana/adminer/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php
 
  mkdir -p $INSTALL_DIR
  wget $DL_LINK \
    -O $INSTALL_DIR/index.php 

  echo 
}

function install_mailpit() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [mailpit]"

  INSTALL_DIR=/opt/mailpit
  BACK_DIR=$(pwd)

  mkdir -p $INSTALL_DIR
  cd $INSTALL_DIR

  DL_LINK=https://github.com/axllent/mailpit/releases/download/v$MAILPIT_VERSION/mailpit-linux-amd64.tar.gz
  wget $DL_LINK

  tar -zxvf *.tar.gz 
  rm -rf *.tar.gz

  echo
}


function install_memcached() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [memcached]"

  apk add memcached=$MEMCACHED_VERSION

  echo
}

function install_nginx() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [nginx]" 

  apk add nginx=$NGINX_VERSION

  echo 
}

function install_openssh() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [openssh]" 

  apk add openssh=$OPENSSH_VERSION

  echo
}

function install_openssl() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [openssl]" 

  apk add openssl=$OPENSSL_VERSION

  echo
}

# --- CONFIGURATION PARTS --- # 
function setup_postgresql() {
  cecho $_BRIGHT_BLUE ":: [CONTAINER] Configuring PostgreSQL..."

  rm -rf $POSTGRESQL_DATA_DIR
  mkdir -p $POSTGRESQL_DATA_DIR
  chown -R postgres:postgres $POSTGRESQL_DATA_DIR
  chmod 700 $POSTGRESQL_DATA_DIR

  su postgres -c "initdb -D $POSTGRESQL_DATA_DIR"
  echo "postgres:$POSTGRESQL_ROOT_PASSWORD" | chpasswd

  mkdir -p /run/postgresql
  chown postgres:postgres /run/postgresql
  chmod 775 /run/postgresql

  su postgres -c "
    pg_ctl \
      -D '$POSTGRESQL_DATA_DIR' \
      -o '-c listen_addresses=$POSTGRESQL_LISTEN_ADDRESSES' \
      -w start
  "

  while ! su postgres -c "pg_isready -q -d postgres"; do
    cecho $_BRIGHT_YELLOW "--- Waiting for PostgreSQL to be ready."
    sleep 1
  done

su postgres -c "psql -v ON_ERROR_STOP=1" <<EOF
  CREATE USER "${POSTGRESQL_USER}" WITH PASSWORD '${POSTGRESQL_PASSWORD}';
  CREATE DATABASE "${POSTGRESQL_USER}" OWNER "${POSTGRESQL_USER}";
  CREATE DATABASE "${POSTGRESQL_PROJECT_DB}" OWNER "${POSTGRESQL_USER}";
EOF

  su postgres -c "
    pg_ctl -D '$POSTGRESQL_DATA_DIR' -m fast stop
  "

  # Wait until PostgreSQL has shut down
  while su postgres -c "pg_isready -q -d postgres"; do
    cecho $_BRIGHT_YELLOW "--- Waiting for PostgreSQL to shut down..."
    sleep 1
  done

  echo
}

function setup_ssh_server() {
  cecho $_BRIGHT_BLUE "# [CONTAINER] Configuring SSH server..."

  # --- listen at 0.0.0.0 
  find_and_replace /etc/ssh/sshd_config "#ListenAddress 0.0.0.0" "ListenAddress 0.0.0.0"

  # --- generate keys 
  sudo ssh-keygen -A

  echo
}

function setup_nginx() {
  cecho $_BRIGHT_BLUE "# [CONTAINER] Setting up nginx..."

  cd /home/$CONTAINER_USER/project/

  sudo rm -rf /etc/nginx/nginx.conf 

  sudo cp ./sites/nginx.conf /etc/nginx/nginx.conf 
  sudo cp ./sites/setup.conf /etc/nginx/http.d/default.conf

  sudo chmod 644 /home/$CONTAINER_USER/project/source
}



# --- INSTALLATION FLOW --- # 
install_python
install_nodejs
install_php 
install_composer
install_adminer
install_mailpit
install_memcached
install_postgresql
install_nginx
install_openssh
install_openssl

# --- CONFIGURATION FLOW --- # 
setup_ssh_server
setup_postgresql
setup_nginx