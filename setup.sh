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

  sudo killall postgres
}

function setup_ssh_server() {
  cecho $_BRIGHT_BLUE "# [CONTAINER] Configuring SSH server..."

  # --- listen at 0.0.0.0 
  find_and_replace /etc/ssh/sshd_config "#ListenAddress 0.0.0.0" "ListenAddress 0.0.0.0"

  # --- generate keys 
  sudo ssh-keygen -D
}

function setup_ssl_certificates() {
  cecho $_BRIGHT_BLUE "# [CONTAINER] Setting up SSL certificates..."

  CA_NAME=lnamps
  CA_DIR=./.lnamps/ca

  CA_KEY=$CA_DIR/private/$CA_NAME.key
  CA_CRT=$CA_DIR/public/$CA_NAME.crt
  CSR_FILE=./source/certificates/$PROJECT_NAME.csr
  EXT_FILE=./source/certificates/$PROJECT_NAME.v3.ext
  KEY_FILE=./source/certificates/$PROJECT_NAME.key
  CRT_FILE=./source/certificates/$PROJECT_NAME.crt

  if [ ! -d "$CA_DIR" ]; then
    cecho $_BRIGHT_GREEN "# [CONTAINER] Creating CA files..."
    mkdir -p "$CA_DIR"
    mkdir -p "$CA_DIR/private"
    mkdir -p "$CA_DIR/public"
    touch "$CA_DIR/STATUS"
    echo "NOT_INSTALLED" > "$CA_DIR/STATUS"

    echo "--- Creating $CA_KEY"
    PASSPHRASE=password
    openssl genrsa \
      -aes256 \
      -passout pass:$PASSPHRASE \
      -out "$CA_KEY" 4096
    
    echo "--- Creating $CA_CRT"
    C="PH"
    ST="Arbitrary"
    L="Arbitrary"
    O="$CA_NAME"
    OU="$CA_NAME"
    CN="$CA_NAME"

    openssl req \
      -x509 \
      -new \
      -nodes \
      -key $CA_KEY \
      -sha256 \
      -days 30000 \
      -out "$CA_DIR/public/$CA_NAME.crt" \
      -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN" \
      -passin pass:$PASSPHRASE 

  else
    cecho $_BRIGHT_GREEN "# [CONTAINER] Existing CA certificate detected..."
  fi 

  cecho $_BRIGHT_GREEN "# [CONTAINER] Creating site certificates..."

  echo "--- Creating CSR file."
  SITE_CERT="$PROJECT_NAME"
  COMMON_NAME="$PROJECT_NAME"
  C="PH"
  ST="Arbitrary"
  L="Arbitrary"
  O="$PROJECT_NAME"
  DNS1="$PROJECT_NAME"
  DNS2="$PROJECT_NAME.lan"

  openssl req -new -nodes \
    -out "$CSR_FILE" \
    -newkey rsa:4096 \
    -keyout "$SITE_CERT" \
    -subj "/CN=$COMMON_NAME/C=$C/ST=$ST/L=$L/O=$O" \
  

  echo "--- Create SAN extension config file."
cat > "$EXT_FILE" <<EOF
  authorityKeyIdentifier=keyid,issuer
  basicConstraints=CA:FALSE
  keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
  subjectAltName = @alt_names

  [alt_names]
  DNS.1 = $DNS1
  DNS.2 = $DNS2
EOF


  # Sign the certificate
  echo "--- Signing the certificate"
  openssl x509 \
    -req \
    -in $CSR_FILE \
    -CA $CA_CRT \
    -CAkey $CA_KEY \
    -CAcreateserial \
    -out $CRT_FILE \
    -days 730 \
    -sha256 \
    -extfile $EXT_FILE \
    -passin pass:$PASSPHRASE

  echo
}


# --- INSTALLATION FLOW --- # 
# install_python
# install_nodejs
# install_php 
# install_composer
# install_adminer
# install_mailpit
# install_memcached
# install_postgresql
# install_nginx
# install_openssh
install_openssl

# --- CONFIGURATION FLOW --- # 
# setup_postgresql
# setup_ssh_server
setup_ssl_certificates