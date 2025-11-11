{
  description = "A kiosk for reading the manual";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    
    ros_assistant.url = "github:IamTheCarl/ros_assistant";

    # ROS Assistant also uses nixpkgs, but may be on a different version than what we're using.
    # You don't have to do this, but you can modify ROS Assistant's inputs to match ours. It will
    # save you some hard drive space.
    ros_assistant.inputs.nixpkgs.follows = "nixpkgs";
    
    # Used to target all major platforms when creating development shells and packages
    flake-utils.url  = "github:numtide/flake-utils";
   
    # Public keys used for ssh login to the target device
    public_keys = {
      # Remember to replace my username with your username.
      url = "https://github.com/IamTheCarl.keys";
    #  url = "https://gitlab.com/USERNAME.keys"; # Alternative for Gitlab users
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ros_assistant, flake-utils, public_keys }: {
    # Configurations for computers we wish to manage with rass are defined here.
    # The name of the system is how rass will know which system we are referencing.
    nixosConfigurations.kiosk = nixpkgs.lib.nixosSystem {  
      system = "x86_64-linux";

      # These are modules that will be used to build the computer's software stack.
      modules =
      let
        # This gives us a nice shortcut for referencing modules provided by rass.
        mods = ros_assistant.rass-modules;
      in [
        (mods + "/basic_boot.nix")
        (mods + "/installer_iso.nix")
        (mods + "/installer_netboot.nix")
        (mods + "/auto_revert.nix")
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
          
          # Configure ssh
          # Letting ssh start before multi-user mode has caused me occasional issues.
          # This starts it a little later in the boot process.
          systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
          services.openssh.enable = true;
	  
          # Root login is normally blocked, as it should be for a public network facing machine.
          services.openssh.settings.PermitRootLogin = "yes";
          users.extraUsers.root.openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile public_keys);
          
          # Install system packages.
          environment.systemPackages = [
            pkgs.cowsay
          ];

          # It's unwise to run a web browser as root.
	  # We'll create a user for that named kiosk.
          users.users.kiosk = {
            isNormalUser = true;
	    group = "kiosk";
          };

	  # And give that user its own group too.
          users.groups.kiosk = {};

          # Enable the graphical target for systemd.
          systemd.targets.graphical.enable = true;

	  # Setup the cage Wayland compositor.
          services.cage = {
            enable = true;
	    user = "kiosk";
	    program = (pkgs.writeScript "kiosk-application" ''
	      #!${pkgs.bash}/bin/bash
              ${pkgs.firefox}/bin/firefox --new-instance --kiosk --private-window https://example.com
	    '');
            environment = {
	      # By default, cage will shutdown if no input devices can be found.
	      # Do not do that. Keep running.
              WLR_LIBINPUT_NO_DEVICES = "1";
            };
	  };
        })
      ];
    };

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
