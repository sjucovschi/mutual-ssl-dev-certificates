#### Generate certificates for testing MSSL in the Orian project

This project creates all files needed for enabling Mutual SSL configuration in the Orian project.
The client and sever certificates are created by using a root certificate authority. The **_ca-cert.pem_** certificate
is used to validate the identity of the two. 

The **_domains.ext_** files define the domain names that these certificates are valid for. I've included **_host.docker.internal_**,
besides localhost, so that MSSL and SSL requests could work between two docker hosts.

The provided script should be run within WSL for Windows or in a Linux Docker container. Some of the openssl commands **do
not work directly under Windows 10**. 

The certificates to use will be copied over to the dist folder. They are named accordingly. 

The folder named **_postman_**, inside the **_dist_** folder, contains certificates that enable testing through Postman. 
Go to Postman/Settings/Certificates and add them there.