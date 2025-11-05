# Installation

ROS Assistant is built and distributed with the [Nix](https://nixos.org) package manager. This package manager is the only thing you need to start using ROS Assistant. We won't be installing ROS Assistant directly into your host system, bust instead into a project folder managed by Nix.

The Nix package manager is a necessary dependency of ROS Assistant. We will be going into greater detail of what Nix is and how it will help you build robots in a later chapter.

The Nix package manager is already pre-installed on [NixOS](https://nixos.org/), but NixOS is not mandatory, and not necessarily easier either, as you will have to learn how to manage your [system configuration](https://nixos.wiki/wiki/Overview_of_the_NixOS_Linux_distribution#Declarative_Configuration) on top of ROS Assistant. You can install Nix on any Linux distro, MacOS, Windows Subsystem for Linux, and other platforms. Please use ROS Assistant in the environment you are most comfortable with.

The official installation instructions for Nix can be found [here](https://nixos.org/download/).


## Enable Flakes

[Flakes](https://nixos.wiki/wiki/flakes) are an experimental feature of Nix. While not entirely stabilized, the features ROS Assistant depends on are stable. Flakes make it easy to include software dependencies from 3rd parties and track exactly which versions you use in git. With this, you can clone a repo you haven't touched for months and get the exact same software stack you had when you left off.

Because some aspects of flakes are [still considered experimental](https://nix.dev/concepts/flakes.html#why-are-flakes-controversial), we will need to enable them.

### On NixOS
To enable flakes on NixOS, add the following to your [system configuration](https://nixos.wiki/wiki/Overview_of_the_NixOS_Linux_distribution#Declarative_Configuration) using your editor of choice.
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### On other distros
To enable flakes on other distros, add the following to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf` using your favorite editor of choice:
```nix
experimental-features = nix-command flakes
```

# Wrapping up
Now that you have setup your Nix environment and enabled flakes, you're ready to start using ROS Assistant. In the next chapter we will be creating your first ROS Assistant project.
