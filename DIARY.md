# DIARY

## Terraform

Ditching Terraform. I'm not creating and destroying servers very often. I can manually do this.

## Hetzner

I'm creating the new server on Hetzner. Starting with the smallest, CX11.

In the "cloud-init configuration" text area, I'm pasting my custom version of [their example script][cloud-init] (just replace the user's name and the authorized key).

After creating the server, you don't have the password for my user nor `root`, so you cannot start a Console from the website.
First you have to reset the root password in the `/rescue` page.

At the beginning of July 2023, 1Password's SSH integration started working. 
I no longer need to keep my private keys in cleartext on my laptop.
WARNING: Check that the vault containing your keys is enabled inside `~/.config/1Password/ssh/agent.toml`.

### IPv6

The provided public address ends with `::/64`, and that's not a valid value for an AAAA record on Gandi.
I created a record with a final `::1` instead.

I used my other linux server with IPV6 connectivity to verify the connection is up and running, and I've discovered that right now `nslookup` and `ssh` are not working as expected on macOS.
I discovered that I can tunnel IPV6 connections when using Mullvad VPN, so now I can access the server also on macOS. I can't use the AAAA record above though.

I thought that `OpenSSH_9.0p1`, from mid 2022, was enough to support connecting to an AAAA record. It seems like I was wrong: a `brew install openssh` fixed the problem.

Running an IPV6 only server requires additional work, e.g. GitHub doesn't support cloning over IPV6.

## Ansible

I abandoned the idea of running ansible directly on the server itself.
Now that 1P SSH + IPV6 works flawlessly, I'll install ansible on my laptop and issue commands directly from there.

[cloud-init]: https://community.hetzner.com/tutorials/basic-cloud-config
