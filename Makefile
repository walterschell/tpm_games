all:
#Note that you will need to modify /etc/crypttab by hand
# nvme0n1p3_crypt UUID=9b2ff30a-bd56-4688-b74d-d9d149b67e1c none luks,discard,keyscript=/usr/local/bin/passphrase-from-tpm

test: seal secret.txt
	sudo bash -c './passphrase-from-tpm 2>/dev/null | cryptsetup luksOpen --test-passphrase --key-slot 1 /dev/nvme0n1p3 && echo "There is a key available with this passphrase." || echo "No key available with this passphrase."'

install: passphrase-from-tpm tpm2.hook.sh
	sudo cp tpm2.hook.sh /etc/initramfs-tools/hooks/tpm2
	sudo chmod 755 /etc/initramfs-tools/hooks/tpm2
	sudo cp passphrase-from-tpm /usr/local/bin/passphrase-from-tpm
	sudo chmod 744 /usr/local/bin/passphrase-from-tpm
	#sudo update-initramfs -v -u -k all
	sudo update-initramfs -u -k all

clean:
	rm -f policy.digest primary.context obj.priv
	rm -f obj.pub load.context seal

secret.txt:
	dd if=/dev/urandom bs=16 count=1 | base64 -w 0 > secret.txt
	chmod 600 secret.txt
	sudo chown root:root secret.txt

install-secret-txt: secret.txt
	sudo cryptsetup luksAddKey /dev/nvme0n1p3 secret.txt

test_key:
	sudo cryptsetup luksOpen --key-file secret.txt --test-passphrase --key-slot 1 /dev/nvme0n1p3 && echo "There is a key available with this passphrase." || echo "No key available with this passphrase."

seal: seal_luks_key.sh secret.txt
	./seal_luks_key.sh

reseal: seal_luks_key.sh secret.txt
	./seal_luks_key.sh

