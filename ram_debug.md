```bash
VM=win10-uefi-test
DISK=/var/lib/libvirt/images/${VM}.qcow2
NVRAM=/var/lib/libvirt/qemu/nvram/${VM}_VARS.qcow2

sudo mkdir -p /var/lib/libvirt/qemu/nvram
sudo qemu-img convert -f raw -O qcow2 /usr/share/OVMF/OVMF_VARS_4M.fd "$NVRAM"
```

Then new VM from ISO & customize before install:
- Enable boot menu 
- Boot options -> CDROM 1st
- Q35 with ```.../OVMF_CODE_4M.fd```
- CPU -> XML add ```<nvram template='/usr/share/OVMF/OVMF_VARS_4M.fd' format='qcow2' >/var/lib/libvirt/qemu/nvram/win10-uefi-test_VARS.qcow2</nvram>```
