source .env 
source utils/shell-helpers.sh

CA_NAME=lnamps
CA_DIR=/home/$CONTAINER_USER/project/tmp/ca
CERT_DIR=./source/certificates

CA_KEY=$CA_DIR/private/$CA_NAME.key
CA_CRT=$CA_DIR/public/$CA_NAME.crt
PASSPHRASE="password"

if [ ! -d "./.lnamps/ca" ]; then
  cecho $_BRIGHT_GREEN "# [CONTAINER] Creating CA key and certificate..."
  login_as_user "mkdir -p ~/project/tmp/ca/"
  login_as_user "mkdir -p ~/project/tmp/ca/private/"
  login_as_user "mkdir -p ~/project/tmp/ca/public/"

  echo "--- Creating CA key..."
  login_as_user "  
    openssl genrsa \
      -aes256 \
      -passout pass:$PASSPHRASE \
      -out "$CA_KEY" 4096
  "

  echo "--- Creating CA certificate..."
  C="PH"
  ST="Arbitrary"
  L="Arbitrary"
  O="$CA_NAME"
  OU="$CA_NAME"
  CN="$CA_NAME"

  login_as_user "
    openssl req \
      -x509 \
      -new \
      -nodes \
      -key $CA_KEY \
      -sha256 \
      -days 10000 \
      -out "$CA_CRT" \
      -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN" \
      -passin pass:$PASSPHRASE 
    "

  mkdir ./.lnamps/ca
  mkdir ./.lnamps/ca/public
  mkdir ./.lnamps/ca/private
  
  incus file pull $PROJECT_NAME/$CA_KEY .lnamps/ca/private/$CA_NAME.key 
  incus file pull $PROJECT_NAME/$CA_CRT .lnamps/ca/public/$CA_NAME.crt 

  login_as_user "  
    rm -rf ~/project/tmp/ca
  "
else
  cecho $_BRIGHT_GREEN "# [CONTAINER] Existing CA certificate detected..."
fi 

login_as_user "
  cd /home/$CONTAINER_USER/project/ && 
  mkdir -p source/certificates &&
  bash ./utils/setup-site-certificates.sh
"