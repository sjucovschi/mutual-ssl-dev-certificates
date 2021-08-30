#### Generate certificates for testing 2 way TLS

This project creates all files needed for enabling testing of a 2 way TLS setup (Mutual SSL).
The client and sever certificates are created by using a root certificate authority. The **_ca-cert.pem_** certificate
is used to validate the identity of the two. 

The **_domains.ext_** files define the domain names that these certificates are valid for. I've included **_host.docker.internal_**,
besides localhost, so that MSSL and SSL requests could work between two docker hosts.

To recreate the certificates run the .sh script in the root folder. The certificates to use will be copied over to the dist folder.

The folder named **_postman_**, inside the **_dist_** folder, contains certificates that enable testing through Postman. 
Go to Postman/Settings/Certificates and add them there.