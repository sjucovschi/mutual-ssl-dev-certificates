#!/usr/bin/env bash

cleanUpExistingCertificatesAndKeystores() {
    echo 'Cleaning up existing certificates and keystores'

    rm -fv client/client-key.pem
    rm -fv client/client.csr
    rm -fv client/client-cert.pem
    rm -fv client/client.p12
    rm -fv client/keystore.jks
    rm -fv client/truststore.jks
  
    rm -fv ca/ca-cert.pem
    rm -fv ca/ca-key.pem
    rm -fv ca/ca-cert.srl

    rm -fv server/server-key.pem
    rm -fv server/server.csr
    rm -fv server/server-cert.pem
    rm -fv server/server-cer-including-private-key.pem

    rm -fv dist/ssl_pps-edenred_chain.pem
    rm -fv dist/ssl_pps-int_chain.pem
    rm -fv dist/ssl_pps-int_full_chain.pem
    rm -fv dist/ssl_pps-int_key.pem
    rm -fv dist/keystore.jks
    rm -fv dist/truststore.jks
 
    rm -r dist/postman
    
  
    echo 'Finished cleanup'
}

createCertificates() {
    echo 'Starting to create certificates...'

    # generate the private key and the certificate for the certificate authority (CA); private key with no passphrase (-nodes)
    openssl req -nodes -x509 -newkey rsa:4096 -keyout ca/ca-key.pem -out ca/ca-cert.pem -days 3650  -subj "/C=UK/ST=Wiltshire/L=Swindon/O=Prepay Solutions/OU=IT Department/CN=PPS Certificate Authority"

    #generate the server private key and server certificate signing request (CSR); private key with no passphrase (-nodes)
    openssl req  -nodes -newkey rsa:4096 -keyout server/server-key.pem -out server/server.csr -subj "/C=UK/ST=Wiltshire/L=Swindon/O=Service Test/OU=IT Department/CN=pps-client.com"

    #generate the client private key and client certificate signing request (CSR); private key with no passphrase (-nodes)
    openssl req -nodes -newkey rsa:4096 -keyout client/client-key.pem -out client/client.csr -subj "/C=UK/ST=Wiltshire/L=Swindon/O=Prepay Solutions/OU=IT Department/CN=pps-int.com"

    #sign the server certificate with the CA
    openssl x509 -req -days 3650 -in server/server.csr -CA ca/ca-cert.pem -CAkey ca/ca-key.pem -CAcreateserial -extfile server/domains.ext -out server/server-cert.pem

    #sign the client certificate with the CA
    openssl x509 -req -days 3650 -in client/client.csr -CA ca/ca-cert.pem -CAkey ca/ca-key.pem -CAcreateserial -extfile client/domains.ext -out client/client-cert.pem

    #add the server private key to the server certificate for the haproxy config
    cat server/server-cert.pem server/server-key.pem > server/server-cer-including-private-key.pem

    echo 'Verify the client certificate...'
    openssl verify -CAfile ca/ca-cert.pem client/client-cert.pem

    echo 'Verify the server certificate...'
    openssl verify -CAfile ca/ca-cert.pem server/server-cert.pem
}

createClientKeyStoreAndTrustStore() {

    #convert the client cert and secret key into a pkcs12 file (mandatory since keytool cannot just import a cert + private key directly); must set a password because step 2 fails otherwise
    openssl pkcs12 -export -in client/client-cert.pem -inkey client/client-key.pem -out client/client.p12 -name client -CAfile ca/ca-cert.pem -chain -passout pass:secret

    #create a java keystore from the pkcs12 file; this will contain the client certificate, encrypted client private key, and the certificate authority (because we added the -chain option for the previous command)
    keytool -importkeystore -deststorepass secret -destkeypass secret -destkeystore client/keystore.jks -srckeystore client/client.p12 -srcstoretype JKS -srcstorepass secret -alias client

    #create a java truststore and import the certificate authority certificate into it (this will validate any certificates signed by the certificate authority)
    keytool -keystore client/truststore.jks -importcert -file ca/ca-cert.pem -alias root-ca -storepass secret -noprompt
}

renameCertificatesToMatchExistingNames() {
    cp ca/ca-cert.pem dist/ssl_pps-edenred_chain.pem

    cp server/server-cert.pem dist/ssl_pps-int_chain.pem
    cp server/server-cer-including-private-key.pem dist/ssl_pps-int_full_chain.pem
    cp server/server-key.pem dist/ssl_pps-int_key.pem

    cp client/keystore.jks dist/keystore.jks
    cp client/truststore.jks dist/truststore.jks

    mkdir dist/postman

    cp ca/ca-cert.pem dist/postman/postman-ca-cert.pem
    cp client/client-cert.pem dist/postman/postman-client-cert.pem
    cp client/client-key.pem dist/postman/postman-client-key.pem
}

cleanUpExistingCertificatesAndKeystores
createCertificates
createClientKeyStoreAndTrustStore
renameCertificatesToMatchExistingNames