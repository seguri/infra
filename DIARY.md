# DIARY

## Terraform

Ditching Terraform. I'm not creating and destroying servers very often. I can manually do this.

## Hetzner

I'm creating the new server on Hetzner. Starting with the smallest, CX11.

In the "cloud-init configuration" text area, I'm pasting my custom version of [their example script][cloud-init] (just replace the user's name and the authorized key).

After creating the server, you don't have the password for my user nor `root`, so you cannot start a Console from the website.
First you have to reset the root password in the `/rescue` page.

Also, the public IPV6 they provide ends with `::/64`, and that's not a valid value for an AAAA record on Gandi.
I created a record with a final `::1` instead.

I used my other linux server with IPV6 connectivity to verify the connection is up and running, and I've discovered that right now `nslookup` and `ssh` are not working as expected on macOS.
I discovered that I can tunnel IPV6 connections when using Mullvad VPN, so now I can access the server also on macOS. I can't use the AAAA record above though.

I tried using 1Password's SSH integration, but it's not working: the ssh key is not found and ssh falls back to password authentication. I'll try again after the next update.


[cloud-init]: https://community.hetzner.com/tutorials/basic-cloud-config

