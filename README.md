# CAPE v2 - Installatio on Proxmox

This is ongoing stuff, personnal notes

## Structure

- **Cape host** : Ubuntu Server 24.04 LXC
- **Cape guest1** : Windows 10 VM

## Network

- **vmbr0** : 10.12.0.0/24 - Proxmox default
- No need of an isolated one, we will put some Proxmox firewalls rules on the guests

## VM, LXC and LAN creation

Let's create the Ubuntu LXC (2 CPUs / 4GB RAM / 24GB SSD), on 10.12.0.70.

Create a ```cape``` user use sudo permissions

Download and edit the cape installer script

```bash
wget https://raw.githubusercontent.com/kevoreilly/CAPEv2/master/installer/cape2.sh
chmod +x cape2.sh
# Setup your IP and INTERFACE inside
```

Then run the ```Base``` installer as ```cape``` user

```bash
sudo ./cape2.sh Base | tee cape-base.log
```

After quite some waiting, its now time to prepare the ```machinery```.\
Before that, huge advice to read the ```conf/``` folder

## Setting up Windows 10 Guest

Download the Microsoft official Windows 10 ISO and the virtio drivers ISO [here](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)\
Create a VM as usual, I gave mine 2 CPUs / 4GB RAM / 64GB SSD for now, will see later.
Since the goal is to have a Guest as realistic as possible, don't put Qemu Agent and other fancy stuff on.

## Setting up the Proxmox REST API

**The plan is** to setup a User, give him an API token, a specific role

In Proxmox Web UI, Datacenter > Permissions > Users > Add :  
![Proxmox API user creation](imgs/pve_useradd.png)  
You can generate a Token ID from a random string of Characters/Numbers.  
Write down username/password for later

Next,  Datacenter > Permissions > API Tokens > Add
![API token creation](imgs/pve_apiadd.png)

Then write down the given Token ID and Secret for later. 

Now, Datacenter > Permissions > Roles > Create
![Role creation](imgs/pve_roleadd.png)  
You can fine tune those Permissions later on, for now I recommend you to simply check all of them, more info [here](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#pveum_permission_management)  

Let's now give the User the created role
Datacenter > Permissions > Add > User Permission
![Permission creation](imgs/pve_permissionadd.png)  

Now you can edit the ```conf/proxmox.conf``` accordingly and put your user credentials from step 1 (not the token/secret)

If you got lost in the process, or want to check if you're good with this section, feel free to check [this](https://i12bretro.github.io/tutorials/0572.html)

## Notes

Maybe Ubuntu server on LXC is stupid  
Screenshots of steps when all setup is done

## Ressources

https://4d5a.re/proxmox-cuckoo-a-powerful-combo-for-your-home-malware-lab/
https://endsec.au/blog/building-an-automated-malware-sandbox-using-cape/
https://github.com/rebaker501/capev2install#getting-some-dependencies-out-of-the-way  
https://i12bretro.github.io/tutorials/0572.html