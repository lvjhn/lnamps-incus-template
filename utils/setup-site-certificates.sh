if [ -f .env ]; then 
  source .env
fi 

if [ -f utils/shell-helper.sh ]; then 
  source utils/shell-helpers.sh
fi

cecho $_BRIGHT_BLUE "# [CONTAINER] Setting up SSL certificates..."

CA_NAME=lnamps
CA_DIR=./.lnamps/ca

CA_KEY=$CA_DIR/private/$CA_NAME.key
CA_CRT=$CA_DIR/public/$CA_NAME.crt
CSR_FILE=./source/certificates/ssl.csr
EXT_FILE=./source/certificates/ssl.v3.ext
KEY_FILE=./source/certificates/ssl.key
CRT_FILE=./source/certificates/ssl.crt
PASSPHRASE=password

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