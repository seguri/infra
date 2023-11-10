# Merge kubectl configs

The configuration of this cluster (visible with `kubectl config`) was to be merged with the one of my employer's cluster.

To merge the two configurations, there are three options:

1. manually add the new values under the existing `clusters`, `contexts` and `users` keys in `~/.kube/config`
2. use `yq` and [some fancy function](https://stackoverflow.com/a/67036496) to merge two YAML files
3. use `kubectl config view --flatten`

I went with the third option. Get the output of `kubectl config` from the remote machine and paste it on your laptop to `/path/to/new/config`. Generate the merged config with:

```bash
cd ~/.kube
cp config config.bak
KUBECONFIG=$HOME/.kube/config.bak:/path/to/new/config kubectl config view --flatten > ~/.kube/config
```
