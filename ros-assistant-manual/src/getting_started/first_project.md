# Your first project

Make sure you have read the [introduction](./introduction.md) before continuing. That chapter explains what this project is.

Creating your first project will require that you have first [installed ROS Assistant's dependencies](./installation.md).

In this chapter we will do the following:
  * Create a development environment you can build and deploy software from
  * Define a system configuration for your hardware
  * Use that environment and system configuration to build an OS image
  * Setup access credentials so that you can remotely log into the system you've created
  * Install that OS image to hardware via one of the following methods
    * A network installer ([PXE Boot](https://en.wikipedia.org/wiki/Preboot_Execution_Environment))
    * A USB installer
  * Push an update to the device over ssh

Note that a completed version of the project can be found in the [demos](https://github.com/IamTheCarl/ros-assistant-manual/tree/master/demos/first_project) directory.

Most of this chapter serves as an introduction to Nix. If you are already well versed in Nix, you can likely get by skipping to [Customizing the project](#customizing-the-project).

## Creating the project

First we will create a directory for your project, initialize git within it, run `nix flake init`, and add `flake.nix` to the git tree:
```bash
[~/demos]$ mkdir first_project

[~/demos/first_project]$ cd first_project/

[~/demos/first_project]$ git init
[...] # Output omitted

[~/demos/first_project]$ nix flake init
wrote: "/home/thecarl/demos/first_project/flake.nix"

[~/demos/first_project]$ git add flake.nix

[~/demos/first_project]$ 
```

### Everything must be in the git tree

The big idea with flakes is reproducibility. No matter how long ago you wrote this code or what machine you build it on, your project is going to produce the same outputs. To prevent temporary files and build artifacts from messing with that, anything not in the git tree is invisible to nix. We **absolutely must** add all our input files to git.

Easy reproducibility is important because:
* You can switch to a new development machine with minimal hassle
* Friends can clone and contribute to your project with little effort
* There is no ambiguity of where what version of software you used for your project
* For advanced users, you can have multiple git branches with different dependency sets. This becomes especially valuable to have if you are working with multiple versions of hardware, as you can quickly switch between the different branches of your software.

### flake.nix

Let's examine this flake.nix file that `nix flake init` just created.

```nix
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}
```

The syntax of Nix is surprisingly complex. Some people call it a scripting language but it really isn't. It's more of a markdown language like toml or json. It's just a lot... Fancier, giving you features like functions, which work more like templates, and map operations, which are more like a tool to apply a list of inputs to a template.

An important thing to remember is that Nix is not procedural. It's not going to run things from top to bottom. If you define a value twice, it's not going to let the second one take precedence. It's just going to fail (unless you're overriding a default value).

Knowing that this is just a data structure, let's break it down.

#### The description 
```nix
description = "A very basic flake";
```

The name of the project. This is what will show on the terminal when building or importing this flake into another project.

#### Inputs
```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
};
```

All package managers have ways to add software sources. These inputs are places Nix can download or build software from. The one shown here provides the entirety of the [nix package store](https://search.nixos.org/packages). It contains all the software needed to build a bootable Linux image.

You may have noticed the `github` in the URL. The github tag is present because this software source pulls software from the [nixos git repository](https://github.com/NixOS/nixpkgs/tree/nixos-unstable).

More details on Flake inputs can be found in [the official Nix manual](https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-flake.html#flake-inputs).

##### Locking inputs
Pulling software from a git repository comes with a caveat: Repositories are constantly changing.

Pulling packages from the latest commit every time would result in our system being built from software that comes from a variety of nixpkgs revisions, which would make for a very messy mish-mash of old and new software. The quality of integration would be very poor and you'd likely end up with a broken system.

One way to avoid this issue would be to update all our software every time you update the system configuration, but that also comes with drawbacks. You would be constantly downloading updates and fully rebuilding your software stack. That would waste a lot of time and network bandwidth.

Nix's solution is to lock your inputs. You can do this by running `nix flake update` in your project folder. This will determine what the latest revision of the nixpkgs repository is and lock you to it.

```bash
[~/Projects/ros_assistant_book/demos/first_project]$ nix flake update
warning: creating lock file '"/home/thecarl/Projects/ros_assistant_book/demos/first_project/flake.lock"': 
• Added input 'nixpkgs':
    'github:nixos/nixpkgs/b3d51a0365f6695e7dd5cdf3e180604530ed33b4?narHash=sha256-4vhDuZ7OZaZmKKrnDpxLZZpGIJvAeMtK6FKLJYUtAdw%3
D' (2025-11-02)

[~/demos/first_project]$ git add flake.lock 
```

We've are now using the latest nixos revision. Any software you install from Nixpkgs will be pulled from that specific commit. As time passes, new revisions will be added to Nixpkgs. If you wish to update to the latest commit again, simply run `nix flake update` again.

More details on locking flakes can be found in [the official Nix manual](https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-flake.html#lock-files).

#### Outputs

Outputs are the products provided our flake. Flakes can provide many types of outputs, but we are particularly interested in the following:
* Derivations - these are essentially packages for Nix. We will dig deeper into them later
* The Development Shell - Entering this environment will give you a shell with all our deployment tools available 
* System Configurations - Configurations for the OS of Robots/Appliances we wish to deploy software to
```
  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
```

This example that `nix flake init` gave us isn't very useful for our purposes, but we can analyze it for a moment before we start editing. It is providing a package called `hello`, which is really just the [hello world program](https://search.nixos.org/packages?channel=25.05&show=hello) being passed forward from our upstream nixpkgs.

The command `nix flake show` can be used to get a quick list of available outputs.
```bash
[~/demos]$ nix flake show
git+file:///home/thecarl/demos
└───packages
    └───x86_64-linux
        ├───default: package 'hello-2.12.2'
        └───hello: package 'hello-2.12.2'
```

##### Output targets

You may find the `x86_64-linux` part of the package path odd. This is just how the Nix flake indicates that this is the CPU+OS that the package is meant for. You will typically not have to worry about this, as long as you select the package for your target platform.

## Customizing the project

Now that we have a very basic understanding of how the flake.nix file is formatted, let's adjust it to our needs.

### Add ROS Assistant as an input

Let's rename our flake and then add the ROS Assistant repository as an input.
Make the following changes to your flake file.
```patch
{
- description = "A very basic flake";
+ description = "A kiosk for reading the manual";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
+   ros_assistant.url = "github:IamTheCarl/ros_assistant";
+
+   # ROS Assistant also uses nixpkgs, but may be on a different version than what we're using.
+   # You don't have to do this, but you can modify ROS Assistant's inputs to match ours. It will
+   # save you some hard drive space.
+   ros_assistant.inputs.nixpkgs.follows = "nixpkgs";
+   
+   # Used to target all major platforms when creating development shells
+   flake-utils.url  = "github:numtide/flake-utils";
  };

- outputs = { self, nixpkgs }: {
+ outputs = { self, nixpkgs, ros_assistant, flake-utils }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}
```

After that, run `nix flake update` to lock your new inputs.

That was a lot more noise noise. ROS Assistant brings in quite a few other software sources, most of them being internal to itself.
ROS Assistant is now available to your project.

## Create a development shell

ROS Assistant provides a command line tool with many useful features. We are specifically going to need the deployment features, so let's create a shell environment with those tools available.

```patch
{
  description = "A kiosk for reading the manual";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    ros_assistant.url = "github:IamTheCarl/ros_assistant";

    # ROS Assistant also uses nixpkgs, but may be on a different version than what we're using.
    # You don't have to do this, but you can modify ROS Assistant's inputs to match ours. It will
    # save you some hard drive space.
    ros_assistant.inputs.nixpkgs.follows = "nixpkgs";
    
    # Used to target all major platforms when creating development shells and packages
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ros_assistant, flake-utils }: {

-   packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
-
-   packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
-
- };
+ # This is a tool that will create packages/shells for all the first
+ # tier platforms supported by Nix. The variable `system` represents
+ # the platform platform we are targeting. Anywhere `x86_64-linux`
+ # would go, this goes.
+ } // (flake-utils.lib.eachDefaultSystem (system: 
+   let
+     # Create a version of nixpkgs specifically for this system.
+     pkgs = import nixpkgs {
+       inherit system;
+     };
+   in
+   {
+     # Provides development shell with tools needed to boostrap the devkit.
+     devShells.default = pkgs.mkShell {
+       # These are packages that will be made available in the shell environment.
+       buildInputs = [
+    # Some code editors default to old sh without this.
+    pkgs.bashInteractive
+
+    # Provides the ROS Assistant `rass` command.
+    ros_assistant.packages.${system}.rass-cli
+  ];
+
+  # This is run on startup of the shell session. It is ideal for setting environment variables.
+  shellHook = ''
+    # Indicates to terminal emulators what your preferred shell is.
+         export SHELL=${pkgs.bashInteractive}/bin/bash
+       '';
+     };
+   }
+ ));
}
```

That was a big change. Hopefully the comments help break down what we're doing here.
Once complete, run the command `nix develop` to enter the development shell you just defined.
```bash
[~/demos/first_project]$ nix develop
# Note that at this point, you are in your development shell. You can type `exit` to exit back into the parent shell.

# If all goes well, you now have the rass command available to you.
[~/demos/first_project]$ rass --help
Usage: rass [-b <build-machine...>] <command> [<args>]

Manages robot workspaces, deployment, and integration with Home Assistant.

Options:
  -b, --build-machine
                    specify a remote build machine to be used to build your
                    project. This is especially useful for cross compiling.
                    specify each machine as `--build-machine 'ssh://hostname
                    x86_64-linux aarch64-linux'`, adjusting the hostname and
                    supported architectures as needed.
  --help            display usage information

Commands:
  new               Create a new robot project.
  deploy            Build and deploy a project.
  ssh               Ssh into your robot's computer.
  firewall          Manage the robot's firewalls.
```

## Creating your first system

To create your first system, simply add the following change:

```patch
{
  description = "A kiosk for reading the manual";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    ros_assistant.url = "github:IamTheCarl/ros_assistant";

    # ROS Assistant also uses nixpkgs, but may be on a different version than what we're using.
    # You don't have to do this, but you can modify ROS Assistant's inputs to match ours. It will
    # save you some hard drive space.
    ros_assistant.inputs.nixpkgs.follows = "nixpkgs";
    
    # Used to target all major platforms when creating development shells and packages
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ros_assistant, flake-utils }: {
+   # Configurations for computers we wish to manage with rass are defined here.
+   # The name of the system is how rass will know which system we are referencing.
+   nixosConfigurations.kisok = nixpkgs.lib.nixosSystem {  
+     system = "x86_64-linux";
+
+     # These are modules that will be used to build the computer's software stack.
+     modules = [];
+   };

  # This is a tool that will create packages/shells for all the first
  # tier platforms supported by Nix. The variable `system` represents
  # the platform platform we are targeting. Anywhere `x86_64-linux`
  # would go, this goes.
  } // (flake-utils.lib.eachDefaultSystem (system:
    let
      # Create a version of nixpkgs specifically for this system.
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      # Provides development shell with tools needed to boostrap the devkit.
      devShells.default = pkgs.mkShell {
        # These are packages that will be made available in the shell environment.
        buildInputs = [
          # Some code editors default to old sh without this.
          pkgs.bashInteractive

          # Provides the ROS Assistant `rass` command.
          ros_assistant.packages.${system}.rass-cli
	];

	# This is run on startup of the shell session. It is ideal for setting environment variables.
	shellHook = ''
	  # Indicates to terminal emulators what your preferred shell is.
          export SHELL=${pkgs.bashInteractive}/bin/bash
        '';
      };
    }
  ));
}
```

This tells Nix that our Kiosk is an x86_64 system running Linux, and nothing else. This system has no bootloader, kernel, or userspace OS. To add such things, we need to add some modules to our system.

## Adding modules

Rass gives you reusable common components for your appliances. They're provided in the form of modules.
We will go through a few common modules to setup your kiosk with everything it needs to receive updates over ssh.

### Basic Boot
For brevity, we're only going to list changes specifically to the system configurations part of the flake.
Let's start by adding the [boot module](../cook_book/system_modules/boot.md). This will provide you with a UEFI compatible bootloader ([GRUB](https://www.gnu.org/software/grub/)).

```patch
    nixosConfigurations.generic-x86 = nixpkgs.lib.nixosSystem {  
      system = "x86_64-linux";

      # These are modules that will be used to build the computer's software stack.
-     modules = [];
+     modules =
+     let
+       # This gives us a nice shortcut for referencing modules provided by rass.
+       mods = ros_assistant.rass-modules;
+     in [
+       (mods + "/basic_boot.nix")
+     ];
    };
```

At this point, you could build an OS boot disk. The issue is that it would be a useless OS, booting up to a login screen and nothing else. Despite the login prompt, there is no way for you to log in. We need to configure our networking, configure ssh, and setup login credentials to do so.

### Adding a custom module

```patch
    nixosConfigurations.generic-x86 = nixpkgs.lib.nixosSystem {  
      system = "x86_64-linux";

      # These are modules that will be used to build the computer's software stack.
      modules =
      let
        # This gives us a nice shortcut for referencing modules provided by rass.
        mods = ros_assistant.rass-modules;
      in [
        (mods + "/basic_boot.nix")
+       ({ pkgs, lib, config, ...}: {
+         # This option defines the first version of NixOS you have installed on this particular machine, and is
+         # used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
+         # Not having it set to the latest NixOS version does not mean you are running outdated/unsupported software.
+         #
+         # Once you have deployed to your system, you will likely never change this value again.
+         # See https://search.nixos.org/options?channel=25.05&show=system.stateVersion&query=stateVersion for more details.
+         system.stateVersion = "25.11";
+       })
      ];
    };
```

The [systemState](https://search.nixos.org/options?channel=25.05&show=system.stateVersion&query=stateVersion) option is an easy point of confusion. Some data on your system is non-[idempotent](https://en.wikipedia.org/wiki/Idempotence), such as network configurations added by [Network Manager](https://wiki.archlinux.org/title/NetworkManager), maps generated by [SLAM algorithms](https://en.wikipedia.org/wiki/Simultaneous_localization_and_mapping), etc.

This data may be damaged if upgrading/downgrading software versions that do not have the needed automatic migration tools. Changing this value should never leave your system in a broken state.

Note that the risks of changing this value can be entirely negated by:
 * Not having any persistent data on your robot/appliance outside of [the nix store](https://wiki.nixos.org/wiki/Nix_(package_manager)#Nix_store)
 * Not using applications outside of Nix's control for system configuration, such as [Network Manager](https://wiki.archlinux.org/title/NetworkManager).

### Enabling networking

Add the following to enable networking.
```patch
    nixosConfigurations.generic-x86 = nixpkgs.lib.nixosSystem {  
      system = "x86_64-linux";

      # These are modules that will be used to build the computer's software stack.
      modules =
      let
        # This gives us a nice shortcut for referencing modules provided by rass.
        mods = ros_assistant.rass-modules;
      in [
        (mods + "/basic_boot.nix")
        ({ pkgs, lib, config, ...}: {
          # This option defines the first version of NixOS you have installed on this particular machine, and is
          # used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
          # Not having it set to the latest NixOS version does not mean you are running outdated/unsupported software.
          #
          # Once you have deployed to your system, you will likely never change this value again.
          # See https://search.nixos.org/options?channel=25.05&show=system.stateVersion&query=stateVersion for more details.
          system.stateVersion = "25.11";

+         # Setup Networking
+         systemd.network.enable = true;
+         networking.useNetworkd = true;
+         networking.hostName = "kiosk";
        })
      ];
    };
```

We do three things here:
 * Enable the Linux network stack
 * Setup [Networkd](https://wiki.archlinux.org/title/Systemd-networkd) to manage the system's network configurations
 * Set 'kiosk" as the system's hostname

The [NixOS Wiki page](https://wiki.nixos.org/wiki/Networking) is an excellent source of additional information on how you can configure your system's network settings.

### Adding SSH credentials

This kiosk currently only has a single user: [root](https://en.wikipedia.org/wiki/Superuser)
This user account is also the same one we will use to push updates to the kiosk over ssh. We need a way to log in through it, securely.

#### Setup public key authentication
We will be using [public key authentication](https://en.wikipedia.org/wiki/Superuser) for this purpose.

To continue with this tutorial, you will need to setup ssh access with (Github)[https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh] or [Gitlab](https://docs.gitlab.com/user/ssh), if you have not yet already done so. Note that both of these link to tutorials to setup your account with ssh access.

While this is not mandatory, it is an easy, secure, and automated way to distribute public keys to your devices.

#### Add your public keys as an input

Add the following to your flake file.

```patch
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    ros_assistant.url = "github:IamTheCarl/ros_assistant";

    # ROS Assistant also uses nixpkgs, but may be on a different version than what we're using.
    # You don't have to do this, but you can modify ROS Assistant's inputs to match ours. It will
    # save you some hard drive space.
    ros_assistant.inputs.nixpkgs.follows = "nixpkgs";
    
    # Used to target all major platforms when creating development shells and packages
    flake-utils.url  = "github:numtide/flake-utils";
    
+   public_keys = {
+     # Remember to replace my username with your username.
+     url = "https://github.com/IamTheCarl.keys";
+     flake = false;
+   };
+   # Alternative for Gitlab users
+   # public_keys = {
+   #   # Remember to replace the placeholder with your username.
+   #   url = "https://gitlab.com/USERNAME.keys";
+   #   flake = false;
+   # };
  };

- outputs = { self, nixpkgs, ros_assistant, flake-utils }: {
+ outputs = { self, nixpkgs, ros_assistant, flake-utils, public_keys }: {
```

Your public keys are now available to Nix as a file downloaded off the internet. The keen eyed may find this odd though. This file is not stored in your git repository, so how are we supposed to guarantee the same software stack is produced from the current git revision, even after our public keys have been updated on Github/Gitlab?

Run `nix flake update` and then check the contents of your `flake.lock` file. You should find something like this in there now.
```json
"public_keys": {
  "flake": false,
  "locked": {
    "narHash": "sha256-GcZspS8KT1fHr06n7GN7PMnCbXc7yF/ZkDqtAG7Rzx8=",
    "type": "file",
    "url": "https://github.com/IamTheCarl.keys"
  },
  "original": {
    "type": "file",
    "url": "https://github.com/IamTheCarl.keys"
  }
},
```

Although the file is not stored in your repository, a [sha256](https://en.wikipedia.org/wiki/SHA-2) hash of it has been recorded. The flake will fail to build if it detects that the keys do not match what it expects.

If you wish to update this hash in the future, run `nix flake update public_keys` to update that single input.

#### Configure ssh

Add the following to your system configuration to configure ssh.

```patch
    nixosConfigurations.generic-x86 = nixpkgs.lib.nixosSystem {  
      system = "x86_64-linux";

      # These are modules that will be used to build the computer's software stack.
      modules =
      let
        # This gives us a nice shortcut for referencing modules provided by rass.
        mods = ros_assistant.rass-modules;
      in [
        (mods + "/basic_boot.nix")
        ({ pkgs, lib, config, ...}: {
          # This option defines the first version of NixOS you have installed on this particular machine, and is
          # used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
          # Not having it set to the latest NixOS version does not mean you are running outdated/unsupported software.
          #
          # Once you have deployed to your system, you will likely never change this value again.
          # See https://search.nixos.org/options?channel=25.05&show=system.stateVersion&query=stateVersion for more details.
          system.stateVersion = "25.11";

          # Setup Networking
          systemd.network.enable = true;
          networking.useNetworkd = true;
          networking.hostName = "kiosk";
          
+         # Configure ssh
+         # Letting ssh start before multi-user mode has caused me occasional issues.
+         # This starts it a little later in the boot process.
+         systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
+         services.openssh.enable = true;
+    
+         # Root login is normally blocked, as it should be for a public network facing machine.
+         services.openssh.settings.PermitRootLogin = "yes";
+         users.extraUsers.root.openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile public_keys);
        })
      ];
    };
```

Public key authentication with ssh is now setup.

## Building the OS boot disk

It has been a long road to get here, but we're finally ready to do something interesting.
Let's build a boot disk image for our target system.

```bash
[~/demos/first_project]$ nix develop

[~/demos/first_project]$ rass deploy disk
[*] ROS Assistant CLI v0.1.0
[*] Building boot disk images.
[*] Project root: "/home/thecarl/Projects/ros_assistant_book/demos/first_project"
[*] Project root: "/home/thecarl/Projects/ros_assistant_book/demos/first_project"
[*] Host filter: None
[W] `nix eval` had stderr output: warning: Git tree '/home/thecarl/Projects/ros_assistant_book' is dirty
 |  
[*] Building 'generic-x86'
warning: Git tree '/home/thecarl/demos/first_project' is dirty
[*] Build successful.

[~/demos/first_project]$ ls -lh result/generic-x86/nixos.img 
-r--r--r-- 1 root root 4.4G Dec 31  1969 result/generic-x86/nixos.img
```

Congratulations! You now have a boot disk image. If you have one of those SATA to USB adapters, you could write this image to a hard drive and plug it into your target system. While that is a valid way to bootstrap your kiosk, we have more elegant ways to bring up our kiosk.

# What's next

Next we'll be creating installers for our boot disk image, and then of course, installing the boot disk image.
