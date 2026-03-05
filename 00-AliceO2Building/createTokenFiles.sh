#/bin/bash

# tokenPath="~/Downloads/myCertificate.p12"
tokenPath="$HOME/A_Rahul_Folder/CERN/CERN_certificates/CERN_cert_2025.12.10/myCertificate.p12"
rm -rf  ~/.globus/usercert.pem  ~/.globus/userkey.pem
mkdir -p ~/.globus
openssl pkcs12 -clcerts -nokeys -in $tokenPath -out ~/.globus/usercert.pem
openssl pkcs12 -nocerts -in $tokenPath -out ~/.globus/userkey.pem
chmod 0400 ~/.globus/userkey.pem

# alienv enter O2Physics/latest 
# alien-token-info
# alien-token-init
# alien-token-destroy
# alien-token-init YOUR_ALIEN_USERNAME
