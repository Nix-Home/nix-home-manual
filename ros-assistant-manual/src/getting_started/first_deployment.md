# First deployment

In the previous chapter we created a new project and defined a system for RASS to deploy to.

This chapter is much easier if you have a basic understanding of the [`/dev`](https://www.baeldung.com/linux/dev-directory) directory.

In this chapter we will perform our initial deployment. Currently our target computer is a husk with no operating system (or the wrong operating system). It will not accept updates over ssh.

There are two methods we can use for deploying to our device for the first time:
* With a [network installer](#pxe-installer-network-installer)
* With an [ISO installer](#iso-installer)

Both methods of deployment require access to the "BIOS Settings" of your [UEFI](https://en.wikipedia.org/wiki/UEFI) firmware and some form of [super user](https://en.wikipedia.org/wiki/Superuser) privledges on your development system. Each deployment method will be explained in detail below.

It should note that both methods do not interfere with each other. You can have the system modules for both modules present in your configuration at the same time.

# A note on selecting boot devices

Most UEFI firmware provides a "quick boot menu" if you hold down F12 during startup. If that is unavailable, often Escape, F2, or F10 can be used to access the "BIOS Settings" of your system. These menus often provide a "quick boot menu" of their own, along with the ability to re-arrange the boot priority order.

# Which hard drive will the installer install to?

By default both the ISO and network installers assume your primary hard drive is `/dev/sda`. If you are using newer hardware or embedded hardware, this device may be `/dev/nvme0n1`. If neither of these devices are correct, you may need to boot your hardware from a [Linux USB](https://ubuntu.com/tutorials/create-a-usb-stick-on-windows#1-overview) and use [fdisk](https://manpage.me/?q=fdisk) to discover the path to the drive you need to install to. A similar technique is covered in the secton on [creating a USB installer](#discovering-your-usb-drive).

Once you know the path to the drive you need to install the OS to, you can override the default by adding the following to your system configuration:
```patch
nixosConfigurations.kiosk = nixpkgs.lib.nixosSystem {  
  system = "x86_64-linux";

  # These are modules that will be used to build the computer's software stack.
  modules =
  let
    # This gives us a nice shortcut for referencing modules provided by rass.
    mods = ros_assistant.rass-modules;
  in [
    (mods + "/basic_boot.nix")
    ({ pkgs, lib, config, ...}: {
+     # Add one or both, depending on which installation methods you choose to add modules for.
+     installer_isoboot.device = "/dev/sdX";
+     installer_netboot.device = "/dev/sdX";

      # Content omitted for breivety
    })
  ];
};
```

# PXE installer (Network installer)

This installation method will produce the necessary files to run [pixiecore](https://github.com/danderson/netboot/tree/main/pixiecore) and then automatically launch the pixiecore application for you.

This is generally the preferred method for first time bring up of a system as it's generally less dangerous to your development system (no risk of writing an ISO image to the wrong drive) and it is typically faster than a USB installation. It is also idea for mass-production of appliances, since this method permits deploying to multiple systems in parallel.

## Adding the network installer module

Add the following to your system configuration:
```patch
nixosConfigurations.kiosk = nixpkgs.lib.nixosSystem {  
  system = "x86_64-linux";

  # These are modules that will be used to build the computer's software stack.
  modules =
  let
    # This gives us a nice shortcut for referencing modules provided by rass.
    mods = ros_assistant.rass-modules;
  in [
    (mods + "/basic_boot.nix")
+   (mods + "/installer_netboot.nix")
    ({ pkgs, lib, config, ...}: {
      # Content omitted for breivety
    })
  ];
};
```

## Deploy

Yes, it's really that easy.
Run `rass deploy install-netboot`.
Rass will typically need super user permissions to open a UDP socket on port 67. It will use sudo to ask you for your password when the time for that comes.

```bash
[~/demos/first_project]$ rass deploy install-netboot
[*] ROS Assistant CLI v0.1.0
[*] Project root: "/home/thecarl/demos/first_project"
[*] Project root: "/home/thecarl/demos/first_project"
[*] Host filter: None
[W] `nix eval` had stderr output: warning: Git tree '/home/thecarl/demos/first_project' is dirty
 |  
[*] Building 'kiosk'
[*] Hosting PXE boot for kiosk, please boot that computer now.
[*] Pixiecore may ask for your password. It needs root privledges to open a UDP socket on port 67.
[*] Press Ctrl-C to end PXE hosting session and continue.
[sudo] password for thecarl: 
[Init] Starting Pixiecore goroutines
```

At this point, boot your system into PXE boot mode. Pixiecore will wait as long as it takes for you to do this, so there is no rush. Once booted, it should detect Pixiecore offering to boot it. You will see something similar to the following on your development sysetm:
```bash
[Init] Starting Pixiecore goroutines
[DHCP] Got valid request to boot 00:60:e0:80:6e:ca (IA32)
[DHCP] Offering to boot 00:60:e0:80:6e:ca
[DHCP] Ignoring packet from 00:60:e0:80:6e:ca: packet is DHCPREQUEST, not DHCPDISCOVER
[TFTP] Send of "00:60:e0:80:6e:ca/0" to 10.10.10.187:2070 failed: "10.10.10.187:2070": sending OACK: client aborted transfer: T
FTP Aborted
[TFTP] clamping blocksize to "10.10.10.187:2071": 1456 -> 1450
[TFTP] Sent "00:60:e0:80:6e:ca/0" to 10.10.10.187:2071
[DHCP] Got valid request to boot 00:60:e0:80:6e:ca (IA32)
[DHCP] Offering to boot 00:60:e0:80:6e:ca
[DHCP] Ignoring packet from 00:60:e0:80:6e:ca: packet is DHCPREQUEST, not DHCPDISCOVER
[HTTP] Get bootspec for 00:60:e0:80:6e:ca took 280ns
[HTTP] Construct ipxe script for 00:60:e0:80:6e:ca took 17.723µs
[HTTP] Sending ipxe boot script to 10.10.10.187:44842
[HTTP] Writing ipxe script to 00:60:e0:80:6e:ca took 2.174µs
[HTTP] handleIpxe for 00:60:e0:80:6e:ca took 47.38µs
[HTTP] Sent file "kernel" to 10.10.10.187:44842
[HTTP] Sent file "initrd-0" to 10.10.10.187:44842
[DHCP] Ignoring packet from 00:60:e0:80:6e:ca: not a PXE boot request (missing option 93)
[DHCP] Ignoring packet from 00:60:e0:80:6e:ca: packet is DHCPREQUEST, not DHCPDISCOVER
```

At this point, the machine should be booted off the netboot installer image, and it is safe to terminate pixiecore. Press `Ctrl-C` to terminate the pixiecore session.

The kiosk will proceed to install its initial boot image. When it is done, it will automatically turn itself off.

# ISO Installer

This installation method will produce an [ISO image](https://en.wikipedia.org/wiki/Optical_disc_image) that can be written to a [USB drive](https://en.wikipedia.org/wiki/USB_flash_drive) or a [Compact Disk](https://en.wikipedia.org/wiki/Compact_disc).

The [network install](#pxe-installer-network-installer) method should generally be preferred over this technique. This technique is best suited for bringing up virtual machines, hardware that cannot support PXE booting, or machines on networks that block PXE booting.

## Adding the USB installer module

Add the following to your system configuration:
```patch
nixosConfigurations.kiosk = nixpkgs.lib.nixosSystem {  
  system = "x86_64-linux";

  # These are modules that will be used to build the computer's software stack.
  modules =
  let
    # This gives us a nice shortcut for referencing modules provided by rass.
    mods = ros_assistant.rass-modules;
  in [
    (mods + "/basic_boot.nix")
+   (mods + "/installer_iso.nix")
    ({ pkgs, lib, config, ...}: {
      # Content omitted for breivety
    })
  ];
};
```

## Build the ISO image

At this point, producing the ISO image is as simple as running the command `rass deploy install-iso`:
```bash
[~/demos/first_project]$ rass deploy install-iso
[*] ROS Assistant CLI v0.1.0
[*] Building installer ISO images.
[*] Project root: "/home/thecarl/demos/first_project"
[*] Project root: "/home/thecarl/demos/first_project"
[*] Host filter: None
[W] `nix eval` had stderr output: warning: Git tree '/home/thecarl/demos/first_project' is dirty
 |  
[*] Building 'kiosk'
warning: Git tree '/home/thecarl/Projects/ros_assistant_book' is dirty
[*] Build successful.

[~/demos/first_project]$ ls -lh result/kiosk/iso/nixos-minimal-25.11pr
e-git-x86_64-linux.iso 
-r--r--r-- 1 root root 1.8G Dec 31  1969 result/kisok/iso/nixos-minimal-25.11pre-git-x86_64-linux.iso
```

That ISO image can be booted by a virtual machine or written to a USB thumb drive to boot real hardware on.

## Write the ISO image to a USB drive

For this example, we will assume our USB drive is located at `/dev/sdX`. Please replace this path with the location to your actual drive. **WARNING:** Providing the wrong location to your USB drive can result in data loss!

### Discovering your USB drive
You can discover the location of your USB drive using the [fdisk](https://manpage.me/?q=fdisk) command.

An abbreviated example of fdisk's output:
```bash
[~/demos/first_project]$ sudo fdisk -l
[sudo] password for thecarl: 

Disk /dev/sdb: 1.92 GiB, 2063597568 bytes, 4030464 sectors
Disk model: USB 2.0 FD      
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x1c3479e7
```

The disk size and model are your best hints to identifying your USB drive.
It is also a valid technique to run fdisk before and after inserting your drive, to see which device appears when it is inserted.
For a more graphical approach, you can use [GNome Disks](https://apps.gnome.org/DiskUtility/) to discover your drive.

### Writing to the USB drive

The [dd](https://manpage.me/?q=dd) command can be used to write your ISO file to your thumb drive.

**WARNING:** Writing your ISO image to the wrong drive/device can result in data loss. Be absolutely certain you have the correct device before continuing.

```bash
[~/demos/first_project]$ sudo dd bs=4M if=result/kisok/iso/nixos-minimal-25.11pre-git-x86_64-linux.iso of=/dev/sdX status=progress oflag=sync
1337982976 bytes (1.3 GB, 1.2 GiB) copied, 2 s, 668 MB/s
446+1 records in
446+1 records out
1871708160 bytes (1.9 GB, 1.7 GiB) copied, 2.80033 s, 668 MB/s

[~/demos/first_project]$
```

### Boot from the drive

You can now plug this USB drive into your kiosk and boot from it. Please see the note on [how to select a boot device](#a-note-on-selecting-boot-devices).

Select your USB boot device from your firmware's boot menu. You will see NixOS boot up and go to a login screen. Simply wait awhile for the installer to do its thing. Eventually it will finish and automatically shut the system down. At this point you can remove the drive and reboot the system from its main hard drive. Your system is now ready.

# Wrapping up

At this point, you've either installed the OS using the [network installer](#pxe-installer-network-installer) or an [ISO installer](#iso-installer). Your system should be booting to a login prompt with a `kiosk login:` welcome screen. This login prompt is not functional, as you have not created any users with a password.

Despite that, you should be able to log into your kisok using ssh:
```bash
[~/demos/first_project]$ ssh root@kiosk.lan
The authenticity of host 'kiosk.lan (10.10.10.187)' can't be established.
ED25519 key fingerprint is SHA256:cGYcb+DWYp69wgKoSZlyLWfq58UHRGjyb++gbnHSjRE.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'kiosk.lan' (ED25519) to the list of known hosts.

[root@kiosk:~]# 
```

# What's next

We now have a system that boots into our custom OS and is accessible via ssh.
In the next chapter we will configure rass for automated login via ssh and use that ssh connection to push updates to the system configuration.
