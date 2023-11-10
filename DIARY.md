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

I used my other linux server with IPv6 connectivity to verify the connection is up and running, and I've discovered that right now `nslookup` and `ssh` are not working as expected on macOS.
I discovered that I can tunnel IPv6 connections when using Mullvad VPN, so now I can access the server also on macOS. I can't use the AAAA record above though.

I thought that `OpenSSH_9.0p1`, from mid 2022, was enough to support connecting to an AAAA record. It seems like I was wrong: a `brew install openssh` fixed the problem.

Running an IPv6 only server requires additional work, e.g. GitHub doesn't support cloning over IPv6.

## Ansible

I abandoned the idea of running ansible directly on the server itself.
Now that 1P SSH + IPv6 works flawlessly, I'll install ansible on my laptop and issue commands directly from there.

## Minikube

I wrote a playbook to install it, then I switched to k3s. Something wasn't working (maybe my VPS is too weak).

## k3s

Currently trying this, on my IPv6-only VPS. I'm using [this repo][seguri-static] to circumvent the impossibility to download raw files from GitHub through IPv6.

### hello-world

To test if k3s is working or not, I found [this][k3s-hello-world].

Obviously it didn't work at the first shot. ngingx container was always stuck in Pending phase and no pods could be scheduled:

```
$ k get nodes
NAME     STATUS                     ROLES                  AGE   VERSION
x        Ready,SchedulingDisabled   control-plane,master   13d   v1.27.3+k3s1
$ k describe nodes
[...]
Taints:             node.kubernetes.io/unschedulable:NoSchedule
Unschedulable:      true
[...]
```

I have no idea what caused this, but `k uncordon <node>` solved the issue.

## microk8s

After abandoning k3s because of its many problems with IPv6, I switched to microk8s.

The playbook was easy to write and covers everything.

I've configured `kubectl` on my laptop as shown [here](help/Merge%20kubectl%20configs.md).

To access the remote dashboard:

- `kubectl port-forward --insecure-skip-tls-verify --context microk8s -n kube-system service/kubernetes-dashboard 10443:443 --address 0.0.0.0`
- open https://localhost:10443/
- in the dashboard, select "kubeconfig" authentication and point to `~/.kube/config`

To remove the `--insecure-skip-tls-verify` flag, ...

[cloud-init]: https://community.hetzner.com/tutorials/basic-cloud-config
[seguri-static]: https://gitlab.com/seguri/static
[k3s-hello-world]: https://www.jeffgeerling.com/blog/2022/quick-hello-world-http-deployment-testing-k3s-and-traefik
