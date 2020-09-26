#!/bin/sh -e
# install to /etc/initramfs-tools/hooks/tpm2
if [ "$1" = "prereqs" ]; then exit 0; fi
echo "sourcing..."
. /usr/share/initramfs-tools/hook-functions
echo "installing unseal..."
copy_exec $(which tpm2_unseal)
echo "installing shared object..."
copy_exec /usr/lib/x86_64-linux-gnu/libtss2-tcti-device.so
