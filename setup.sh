if [ -f .env ]; then 
  source .env
fi 

if [ -f utils/shell-helper.sh ]; then 
  source utils/shell-helpers.sh
fi

# --- INSTALL PYTHON3 --- # 
function install_python() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [python3 and pip]"
  apk add python3=3.12.11-r0 py3-pip=25.1.1-r0
  echo
}

# --- INSTALL NODEJS --- # 
function install_nodejs() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [nodejs and npm]"
  apk add nodejs=$NODE_VERSION npm=$NPM_VERSION
  echo 
}

# --- INSTALL PHP --- # 
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
  echo
}

# --- INSTALL COMPOSER --- # 
function install_composer() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [composer]"
  php84 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php84 -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
  php84 composer-setup.php
  php84 -r "unlink('composer-setup.php');"
  mv composer.phar /usr/bin/composer
}

# --- INSTALL POSTGRESQL --- # 
function install_postgresql() {
  cecho $_BRIGHT_BLUE "[CONTAINER] INSTALLING [postgresql]"
  apk add postgresql$POSTGRESQL_VERSION 
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

}

# --- FLOW --- # 
install_python
install_nodejs
install_php 
install_composer
install_postgresql