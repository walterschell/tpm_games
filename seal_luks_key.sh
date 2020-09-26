#!/bin/bash
set -e
echo "Creating policy..."
# Outputs current hash of PCRs to policy.digest
sudo tpm2_createpolicy --policy-pcr -l sha256:0,1,2,7 -L policy.digest -T device:/dev/tpmrm0

echo "Creating ephemeral primary..."
# Generates new ephemeral primary using ecc ahd sha256 and outputs it to primary.context
sudo tpm2_createprimary -C e -g sha256 -G ecc -c primary.context -T device:/dev/tpmrm0


echo "Creating object..."
# Creates a new object protects by the pcr policy representing encrypted secret
# noda - Authorization failures do not affect lockout count
# adminwithpolicy - Only allow policy based authorization, no password
# fixedparent - Do not allow tpm2_duplicate
# fixedtpm - Do not allow duplication onto another tpm
sudo tpm2_create -C primary.context -u obj.pub -r obj.priv -L policy.digest -a "noda|adminwithpolicy|fixedparent|fixedtpm" -i secret.txt -T device:/dev/tpmrm0


echo "Loading object..."
# Loads newly created object and saves handle to context
sudo tpm2_load -C primary.context -u obj.pub -r obj.priv -c load.context -T device:/dev/tpmrm0
sudo tpm2_getcap handles-transient -T device:/dev/tpmrm0

echo "Removing old object if any.."
# Removes old contents of the handle
sudo tpm2_evictcontrol -c 0x81000000 || echo "Handle did not exist"

echo "Persisting object..."
# Persists to Owner hierarchy in well known handle 0x81000000
sudo tpm2_evictcontrol -C o -c load.context -T device:/dev/tpmrm0


echo "Verifying"
sudo tpm2_getcap handles-persistent -T device:/dev/tpmrm0
sudo tpm2_readpublic -c 0x81000000 -T device:/dev/tpmrm0

echo "Sealed" > seal
