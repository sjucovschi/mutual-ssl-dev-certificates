#!/usr/bin/env bash

cleanUpExistingCertificatesAndKeystores() {
    echo 'Cleaning up existing certificates and keystores'

    rm -fv client/client-key.pem
    rm -fv client/client.csr
    rm -fv client/client-cert.pem
    rm -fv client/client.p12
    rm -fv client/keystore.jks

    rm -fv ca/ca-cert.pem
    rm -fv ca/ca-key.pem
    rm -fv ca/ca-cert.srl
    rm -fv ca/truststore.jks

    rm -fv server/server-key.pem
    rm -fv server/server.csr
    rm -fv server/server-cert.pem
    rm -fv server/server-cert-including-private-key.pem
    rm -fv server/server.p12
    rm -fv server/keystore.jks

    rm -fv dist/client-keystore.jks
    rm -fv dist/server-keystore.jks
    rm -fv dist/truststore.jks
 
    rm -r dist/postman
    
  
    echo 'Finished cleanup'
}

createCertificates() {
    echo 'Starting to create certificates...'

    # generate the private key and the certificate for the certificate authority (CA); private key with no passphrase (-nodes)
    openssl req -nodes -x509 -newkey rsa:4096 -keyout ca/ca-key.pem -out ca/ca-cert.pem -days 3650  -subj "/C=RO/ST=Bucharest/L=Bucharest/O=Jucosystems/OU=IT Department/CN=Jucosystems Certificate Authority"

    #generate the server private key and server certificate signing request (CSR); private key with no passphrase (-nodes)
    openssl req  -nodes -newkey rsa:4096 -keyout server/server-key.pem -out server/server.csr -subj "/C=RO/ST=RO/L=Bucharest/O=Client Service/OU=IT Department/CN=client-service.com"

    #generate the client private key and client certificate signing request (CSR); private key with no passphrase (-nodes)
    openssl req -nodes -newkey rsa:4096 -keyout client/client-key.pem -out client/client.csr -subj "/C=RO/ST=Bucharest/L=Bucharest/O=Server Service/OU=IT Department/CN=server-service.com"

    #sign the server certificate with the CA
    openssl x509 -req -days 3650 -in server/server.csr -CA ca/ca-cert.pem -CAkey ca/ca-key.pem -CAcreateserial -extfile server/domains.ext -out server/server-cert.pem

    #sign the client certificate with the CA
    openssl x509 -req -days 3650 -in client/client.csr -CA ca/ca-cert.pem -CAkey ca/ca-key.pem -CAcreateserial -extfile client/domains.ext -out client/client-cert.pem

    #add the server private key to the server certificate for the haproxy config
    cat server/server-cert.pem server/server-key.pem > server/server-cert-including-private-key.pem

    echo 'Verify the client certificate...'
    openssl verify -CAfile ca/ca-cert.pem client/client-cert.pem

    echo 'Verify the server certificate...'
    openssl verify -CAfile ca/ca-cert.pem server/server-cert.pem
}

createClientKeyStoreAndTrustStore() {

    #convert the client cert and secret key into a pkcs12 file (mandatory since keytool cannot just import a cert + private key directly); must set a password because next step fails otherwise
    openssl pkcs12 -export -in client/client-cert.pem -inkey client/client-key.pem -out client/client.p12 -name client -CAfile ca/ca-cert.pem -chain -passout pass:secret

    #create a java keystore for the client service from the pkcs12 file; this will contain the client certificate, encrypted client private key, and the certificate authority (because we added the -chain option for the previous command)
    keytool -importkeystore -deststorepass secret -destkeypass secret -destkeystore client/keystore.jks -srckeystore client/client.p12 -srcstoretype JKS -srcstorepass secret -alias client

    #convert the server cert and secret key into a pkcs12 file (mandatory since keytool cannot just import a cert + private key directly); must set a password because next step fails otherwise
    openssl pkcs12 -export -in server/server-cert.pem -inkey server/server-key.pem -out server/server.p12 -name server -CAfile ca/ca-cert.pem -chain -passout pass:secret

    #create a java keystore for the server service from the pkcs12 file; this will contain the server certificate, encrypted server private key, and the certificate authority (because we added the -chain option for the previous command)
    keytool -importkeystore -deststorepass secret -destkeypass secret -destkeystore server/keystore.jks -srckeystore server/server.p12 -srcstoretype JKS -srcstorepass secret -alias server

    #create a java truststore and import the certificate authority certificate into it (this will validate any certificates signed by the certificate authority)
    keytool -keystore ca/truststore.jks -importcert -file ca/ca-cert.pem -alias root-ca -storepass secret -noprompt
}

createDist() {

    cp client/keystore.jks dist/client-keystore.jks
    cp server/keystore.jks dist/server-keystore.jks
    cp ca/truststore.jks dist/truststore.jks

    mkdir dist/postman

    cp ca/ca-cert.pem dist/postman/postman-ca-cert.pem
    cp client/client-cert.pem dist/postman/postman-client-cert.pem
    cp client/client-key.pem dist/postman/postman-client-key.pem
}

cleanUpExistingCertificatesAndKeystores
createCertificates
createClientKeyStoreAndTrustStore
createDist