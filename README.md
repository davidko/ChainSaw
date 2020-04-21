# Chainsaw: An automatic energy weapon chain-fire plugin

## Introduction

This plugin, when enabled, automatically detects and chain-fires all energy
weapons on a ship. It fires them at a rate of (maxPeriod / numEnergyWeapons),
where maxPeriod is the "delay" of the slowest firing energy weapon. 

## Setup

Copy "chainsaw" folder into your ".vendetta/plugins/" directory. 

Bind the command "+shootchainsaw" to your primary trigger.

## Commands

### chainsaw.enable

    chainsaw.enable

Enables chain-firing

### chainsaw.disable

    chainsaw.disable

Disables chain-firing

### chainsaw.toggle

    chainsaw.toggle

Toggles chain-firing

## Working principle

When enabled, Chainsaw scans all items on your ship looking for items without a
"Capacity" in the description but with a "Delay". After saving the previously
configured weapon groups, it configures new weapon groups; one group for each
detected energy weapon. It also finds the maximum delay out of all of the
detected energy weapons.

When the trigger is held down, it cycles through the weapon groups with a delay of 
maxDelay / numEnergyWeapons between each weapon group.

If/when chainsaw is disabled, it (tries to) restore the previously saved weapon
groups. (See errata)

## Errata

* chainsaw sometimes doesn't correctly restore the user's weapon groups when it
  is disabled. I'm not sure if this is a problem with saving the weapon groups
  correctly or with loading the saved weapon groups.

* It is currently not possible to only chainfire a subset of energy weapons.
  For instance, if you have 2neuts and 2gauss on a hornet, this plugin
  currently cannot chainfire only the 2 neuts.

* Chainsaw currently does not remember if it is enabled or disabled across
  sessions. This means, if you want to use it, you will have to enable it every
  time you log in.
