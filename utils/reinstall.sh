rm -rf .config/incus 
sudo rm -rf /var/lib/incus 
sudo ip link delete incusbr0 
sudo ip link delete lnamps
sudo umount -l /var/lib/incus/guestpai
sudo umount -l /var/lib/incus/shmounts
sudo apt remove incus incus-client 
sudo apt install incus incus-client
