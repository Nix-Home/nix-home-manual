# Pushing updates

At this point you have a system that boots and permits you to manually log in via ssh.

In this chapter we will:
* Setup rass with the ability to log in via ssh automatically
* Setup auto-revert
* Push a delta update over ssh
* 

# Setting up automated login

You have likely noticed an `ssh_config` file show up in your project directory at some point:
```bash
[~/demos/first_project]$ ls -1
flake.lock
flake.nix
ssh_config # This oddball.
```

This is a bog-standard ssh config file. You can read [its man page](https://manpage.me/?q=ssh_config) for details of how to use it. For now though, add the following to setup automated login:
```
Host kiosk
    HostName kiosk # If your home network likes to add .lan to host names, you can add that here.
    User root # Necessary if your current username is not (you absolutely should not be root right now)
```

If you have done this correctly, you can test the configuration by using rass to log in to the kiosk:
```bash
[~/demos/first_project]$ rass ssh
[*] Nix Home CLI v0.1.0
[*] Project root: "/home/thecarl/demos/first_project"
[*] Project root: "/home/thecarl/demos/first_project"
[*] Host filter: None
[W] `nix eval` had stderr output: warning: Git tree '/home/thecarl/demos/first_project' is dirty
 |  

[root@kiosk:~]# 
```

# Setting up auto-revert

Imagine you push an update to the kiosk that disables the network. Ooops, now we can't log into the device or push an update to fix it! Auto-revert is here to save you. This tool is a safety net that verifies that rass can still connect to the kiosk after an update is applied. If it fails to verify connectivity within a certain tame frame, the update will automatically be reverted to the previous state.

Auto-revert must be setup before you can push an update over ssh, otherwise rass will consider this update unsafe to push. This behavior can be overridden, but doing so is not recommended, especially when setting it up is so easy.

Setting up auto-revert is as simple as adding a single module:
```patch
nixosConfigurations.kiosk = nixpkgs.lib.nixosSystem {  
  system = "x86_64-linux";

  # These are modules that will be used to build the computer's software stack.
  modules =
  let
    # This gives us a nice shortcut for referencing modules provided by rass.
    mods = nix-home.rass-modules;
  in [
    (mods + "/basic_boot.nix")
    (mods + "/installer_iso.nix")
    (mods + "/installer_netboot.nix")
+   (mods + "/auto_revert.nix")
    ({ pkgs, lib, config, ...}: {
      # Content omitted for breivety
    })
  ];
};
```

# Pushing an update

Your system is now ready for an update. Considering how complex everything has been up to this point, this will be shockingly easy. Let's add the program [cowsay](https://cowsay.diamonds/) to our system.

Add the following to your system configuration:
```patch
    nixosConfigurations.kiosk = nixpkgs.lib.nixosSystem {  
      system = "x86_64-linux";

      # These are modules that will be used to build the computer's software stack.
      modules =
      let
        # This gives us a nice shortcut for referencing modules provided by rass.
        mods = nix-home.rass-modules;
      in [
        (mods + "/basic_boot.nix")
        (mods + "/installer_iso.nix")
        (mods + "/installer_netboot.nix")
        (mods + "/auto_revert.nix")
        ({ pkgs, lib, config, ...}: {
          # Content omitted for breivety
          
+         # Install system packages.
+         environment.systemPackages = [
+           pkgs.cowsay
+         ];
        })
      ];
    };
```

Run the command `rass deploy ssh` to push this change to the kiosk.

```bash
[~/demos/first_project]$ rass deploy ssh
[*] Nix Home CLI v0.1.0
[*] Project root: "/home/thecarl/demos/first_project"
[*] Project root: "/home/thecarl/demos/first_project"
[*] Host filter: None
[*] Deploying kiosk to root@kiosk
[*] Setting auto-revert timer using ssh.
[*] Ssh successful.
[*] Timer will start on system activation.
building the system configuration...
copying 14 paths...
copying path '/nix/store/693va8pdmhhcd8vcx6cqkg5ipqc8af52-cowsay-3.8.4' to 'ssh://root@kiosk'...
copying path '/nix/store/g1d6kc6zrpllhsi1y6gy1agy2f21a7p0-nixos-rebuild' to 'ssh://root@kiosk'...
copying path '/nix/store/nb9wciicx0cj2a6vqx61a8994isj3s2i-cowsay-3.8.4-man' to 'ssh://root@kiosk'...
copying path '/nix/store/26lc0za07y33n3kxs47vqn67y9yw207a-unit-script-auto-revert-start' to 'ssh://root@kiosk'...
copying path '/nix/store/afq1lyscz1hsdrc4fxncfb4dhngdxjbq-system-path' to 'ssh://root@kiosk'...
copying path '/nix/store/j2pr3w796mhsw7w2n5ng6yd5s9l11fgv-unit-auto-revert.service' to 'ssh://root@kiosk'...
copying path '/nix/store/09bihdsr4vwsvh4s363wlc5q6hw7xkz4-dbus-1' to 'ssh://root@kiosk'...
copying path '/nix/store/1195zvpp7603xv6zqgikskly9y3ffkq6-X-Restart-Triggers-dbus' to 'ssh://root@kiosk'...
copying path '/nix/store/5k0xvkirlg9lrni5a62qj5b4wrcqwfaw-unit-dbus.service' to 'ssh://root@kiosk'...
copying path '/nix/store/7phrspfk67phlwa29pwjganvsk6ray4q-unit-dbus.service' to 'ssh://root@kiosk'...
copying path '/nix/store/rc9ydvsdfxmd311ikwsdjviv372kn48w-user-units' to 'ssh://root@kiosk'...
copying path '/nix/store/kz27n8k26in9ny8zk045xrs90wsdpv1v-system-units' to 'ssh://root@kiosk'...
copying path '/nix/store/nnp0pkjk47gkp9c7gxi9kj3270cagmqj-etc' to 'ssh://root@kiosk'...
copying path '/nix/store/xg3y26830ham120x99a6lf6h2xqpnw2v-nixos-system-kiosk-25.11.20251105.ae814fd' to 'ssh://root@kiosk'...
activating the configuration...
setting up /etc...
reloading user units for root...
restarting sysinit-reactivation.target
reloading the following units: dbus.service
the following new units were started: auto-revert.service, sysinit-reactivation.target, systemd-tmpfiles-resetup.service
Done. The new configuration is /nix/store/xg3y26830ham120x99a6lf6h2xqpnw2v-nixos-system-kiosk-25.11.20251105.ae814fd
[*] Cancelling auto-revert timer using ssh.
[*] Ssh successful.
```

Now you can log into the kiosk and verify that the cow can indeed say:
```bash
[~/demos/first_project]$ rass ssh
[*] Nix Home CLI v0.1.0
[*] Project root: "/home/thecarl/demos/first_project"
[*] Project root: "/home/thecarl/demos/first_project"
[*] Host filter: None
Last login: Sun Nov  9 04:19:22 2025 from 10.10.10.176

[root@kiosk:~]# cowsay 'It took nearly 7000 words of instruction to get here, but here I am!'
 _________________________________________
/ It took nearly 7000 words of            \
\ instruction to get here, but here I am! /
 -----------------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

Amazing!

# Reverting changes

We've already talked about [auto revert](#setting-up-auto-revert). That is more of an emergency recover tool, for when you leave your machine in an unreachable state. There are more formal ways to restore previous states of the system.

## Test deploys

If you reboot your system right now, the cowsay command will actually disappear. That's because rass uses test deploys by default. These deploys don't commit the system state to the bootloader, so rebooting will cause the state to be lost. Add the `--switch` flag to commit this change to the bootloader. This will make the system state consistent between reboots.

## Selecting generations

Your previous generations are stored. Try doing a `--switch` deploy and then listing your generations.
```bash
[root@kiosk:~]# nix-env --list-generations --profile /nix/var/nix/profiles/system
   1   2025-11-08 19:10:20   
   2   2025-11-09 05:38:09   (current)

[root@kiosk:~]# sudo nix-env --switch-generation 1 -p /nix/var/nix/profiles/system
switching profile from version 2 to 1

[root@kiosk:~]# nix-env --list-generations --profile /nix/var/nix/profiles/system
   1   2025-11-08 19:10:20   (current)
   2   2025-11-09 05:38:09   
```

Of course this is generally unnecessary, as you can simply revert your project to a previous commit and re-deploy that.
However, there is one situation in which it is extremely valuable: When you have a bricked system.

## Selecting a generation at bootup

So let's say you've modified the system in a way it cannot boot anymore. You can still recover from this without reinstalling the OS. Hook up a keyboard and monitor. During the boot process, a GRUB boot menu will come up. Press any key to cancel the countdown timer and select `NixOS - All configurations`. From there you can select a generation from before you broke your system.

# What's next

You now have a kiosk system that you can safely, reliably, and conveniently push software updates to.
Next we are going to put together an actual application for it by bringing up a graphical environment, loading firefox in kisok mode, and then pointing it to a copy of this manual stored locally.
