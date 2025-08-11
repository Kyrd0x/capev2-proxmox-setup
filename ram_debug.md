```bash
VM=win10-uefi-test
NVRAM=/var/lib/libvirt/qemu/nvram/${VM}_VARS.qcow2
# cat for later

sudo mkdir -p /var/lib/libvirt/qemu/nvram
sudo qemu-img convert -f raw -O qcow2 /usr/share/OVMF/OVMF_VARS_4M.fd "$NVRAM"
```

Then new VM from ISO & customize before install:
- Enable boot menu 
- Boot options -> CDROM 1st
- Q35 with ```.../OVMF_CODE_4M.fd```
- CPU -> XML add:
```xml
<nvram template='/usr/share/OVMF/OVMF_VARS_4M.fd' format='qcow2' >
    /var/lib/libvirt/qemu/nvram/<$NVRAM-value>
</nvram>
```
