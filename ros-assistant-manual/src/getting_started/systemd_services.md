# Systemd

[Systemd](https://en.wikipedia.org/wiki/Systemd) is a system management suit for Linux. It's difficult to summarize, but it's essentially "the boss in charge" of your Linux system. It controls the system state (booting, powered on, suspended, off, etc), starts/stops services like your audio and graphics, and sets up system resources like the communications channels between those services.

This is not meant to be a full tutorial on Systemd, but we will introduce you to the idea of services and define one in our flake. We will use services to add functionality to our kiosk.

By the end of this chapter we will have added a graphical user interface and configure a Firefox browser instance to open in kiosk mode.

## Systemd services

A systemd service is simply a program that is started by systemd. It could be a daemon (a program that constantly run in the background) or a one shot program that will quickly do its thing and then terminate. They have many other features that can be configured, especially pertaining to security. We will not be going into depth with those features, or even writing our own for this project.

## Systemd targets

A systemd target is a group of services and other resources that are related. For example, we have the graphical target. The graphical target brings up a graphical desktop on most Linux distributions. We will need to enable it for this project so that our graphical services load.

# Cage Compositor

[Cage](https://github.com/cage-kiosk/cage) is a [Wayland](https://en.wikipedia.org/wiki/Wayland_(protocol)) compositor for Linux. The purpose of a compositor, as its name suggests, is to compose the outputs of graphical applications on our display.

We are going to start Cage as a systemd service. Normally the configuration for this is (quite involved)[https://github.com/cage-kiosk/cage/wiki/Starting-Cage-on-boot-with-systemd], but noble contributors to the Nix project have provided use with a convenient [abstraction](https://search.nixos.org/options?channel=25.05&query=services.cage) for us to leverage.

# Firefox

Surely you have heard of Firefox. For this project, we will be using Firefox in (Enterprise Kiosk Mode)[https://support.mozilla.org/en-US/kb/firefox-enterprise-kiosk-mode]. This can be done by simply passing the appropriate command line arguments.

# Setting it up

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
      # Truncated for brevity.

     # It's unwise to run a web browser as root.
+     # We'll create a user for that named kiosk.
+     users.users.kiosk = {
+       isNormalUser = true;
+       group = "kiosk";
+     };
+
+     # And give that user its own group too.
+     users.groups.kiosk = {};
+
+     # Enable the graphical target for systemd.
+     systemd.targets.graphical.enable = true;
+
+     # Setup the cage Wayland compositor.
+     services.cage = {
+       enable = true;
+       user = "kiosk";
+       program = (pkgs.writeScript "kiosk-application" ''
+         #!${pkgs.bash}/bin/bash
+         ${pkgs.firefox}/bin/firefox --new-instance --kiosk --private-window https://example.com
+       '');
+       environment = {
+         # By default, cage will shutdown if no input devices can be found.
+         # Do not do that. Keep running.
+         WLR_LIBINPUT_NO_DEVICES = "1";
+       };
+     };
    })
  ];
};
```

At this point you can run `rass deploy ssh` and the contents of [example.com](https://example.com) should appear on your kiosk's display.
