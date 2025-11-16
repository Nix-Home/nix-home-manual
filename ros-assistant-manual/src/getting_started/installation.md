# Installation

Make sure you have read the [introduction](./introduction.md) before continuing with installation. It will tell you what we're going to be doing with these tools.

The following dependencies must be installed on your development system to utilize Nix Home.

## Text Editor

Nix Home was designed to be extremely independent of IDE or text editor. All text editors are equally supported, or should I say, unsupported. Integration with [direnv](https://direnv.net/) can make for cleaner integration between your editor and Nix but is far from mandatory. See the [Editor Integration](./cook_book/editor_integration.md) recipe for more details.

## Git

Git is mandatory for using Nix Home. [Everything must be in the git tree](./first_project.html#everything-must-be-in-the-git-tree). 

If you do not know how to use git, you will need to learn. You will at least need to know how to:
* Initialize a git repository
* Add files to the git tree
* Make a commit

A tutorial on how to use git is outside the scope of this guide. A tutorial can be found [here](https://git-scm.com/docs/gittutorial).

## Nix

Nix Home is built and distributed with the [Nix](https://nixos.org) package manager. We won't be installing Nix Home directly into your development system, but instead into a project folder managed by Nix. We will be going into greater detail of what Nix is and how it will help you build your kiosk in the next chapter.

The Nix package manager is already pre-installed on [NixOS](https://nixos.org/), but NixOS is not mandatory, and not necessarily easier either, as you will have to learn how to manage your [system configuration](https://nixos.wiki/wiki/Overview_of_the_NixOS_Linux_distribution#Declarative_Configuration) on top of Nix Home. You can install Nix on any other Linux distro, MacOS, or Windows Subsystem for Linux. Please use Nix Home in the environment you are most comfortable with.

The official installation instructions for Nix can be found [here](https://nixos.org/download/).


### Enable Flakes

[Flakes](https://nixos.wiki/wiki/flakes) are an experimental feature of Nix. While not entirely stabilized, the features Nix Home depends on are stable. Flakes make it easy to include software dependencies from 3rd parties and track exactly which versions you use in [git](https://git-scm.com/). With this, you can clone a repo you haven't touched for months and get the exact same software stack you had when you left off.

Because some aspects of flakes are [still considered experimental](https://nix.dev/concepts/flakes.html#why-are-flakes-controversial), we will need to enable them.

#### On NixOS
To enable flakes on NixOS, add the following to your [system configuration](https://nixos.wiki/wiki/Overview_of_the_NixOS_Linux_distribution#Declarative_Configuration) using your text editor of choice.
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

#### On other distros
To enable flakes on other distros, add the following to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf` using your text editor of choice:
```nix
experimental-features = nix-command flakes
```

# Wrapping up
Now that you have setup your Nix environment and enabled flakes, you're ready to start Nix Home. In the next chapter we will be creating your first Nix Home project.
