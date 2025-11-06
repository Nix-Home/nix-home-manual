# Getting Started

This tutorial will start you on your first ROS Assistant project. This project will teach you the workflow for setting up a ROS Assistant appliance and pushing updates to it over ssh. The appliance you will create is a simple kiosk that displays this very manual. 
The kiosk will have the following features:
* Display a locally stored web page
* Permit the user to interact with the web page using a keyboard and mouse
* Not permit the user to exit the web page by any means, such as keyboard shortcuts

Later tutorials will add more complex and interesting functionality to this kiosk.

Most laptops made within the last 10 years are qualified for this purpose. Shopping at PC repair shops or politely asking your company or school's IT department for decommissioned hardware are good ways to find affordable solutions.

[Virtual hardware](../cook_book/virtual_machines.md) can also be used for this tutorial, but this does add complexity.

It should be noted that you can work through the entirety of the [installation](./installation.md) and [first project](./first_project.md) chapters without hardware.

## Selecting Hardware

Single board computers such as the Raspberry Pi are supported but require [special configuration](./cook_book/raspberry_pi.md). Virtual Machine environments such as [QEMU](https://www.qemu.org/) or [Virtual Box](https://www.virtualbox.org/) do meet the requirements of these tutorials, but also require [virtual machine specific setup](./cook_book/virtual_box.md).

Laptops, desktops, and mini computers that meet these requirements will be suitable for this tutorial.

### Minimum requirements
A device with the following minimal hardware should be sufficient for our kiosk
* Compatible with Linux
  * Ubuntu's [Certified Hardware Database](https://ubuntu.com/certified) is an easy way to search for specific computer models that work well with Linux.
  * [linux-hardware.org](https://linux-hardware.org) is an advanced but valuable resource for looking up hardware compatibility. It goes into much more detail about what specific components are supported and has a larger database of systems.
* A [64bit x86 CPU](https://en.wikipedia.org/wiki/X86-64)
* [UEFI firmware](https://en.wikipedia.org/wiki/UEFI)
  * The ability to access the UEFI firmware settings (the "BIOS menu")
  * Access to the boot order configuration
* 8Gb persistent storage device
* 2Gb RAM
* Ethernet Interface
* Video output of 1024x600@30Hz or better
* A keyboard
* A mouse or touch screen

Future projects in this book would benefit from the following additional hardware:
* A Wifi chip set
* Video input (a web camera)
* Audio output

# What's next

Next we will be installing necessary software on your development machine. That chapter can be fully completed if you haven't already acquired your hardware.
