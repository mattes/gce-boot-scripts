# Rails Boot Script

[Cloud-init file](dist/cloud-init.yml) to boot a Rails app meant to be used with Google's Container Optimized OS.

See also, [My own Heroku in 30 mins - Deploy Rails apps to Google Cloud Compute Engine](https://gist.github.com/mattes/8f00da1f8ec55712e212f51a14745835).

## Usage

* Use as`user-data` metadata field with a Compute Engine VM.
* Search and replace the following variables:
  * `${{DOCKER_IMAGE}}`
  * `${{SECRETS_PREFIX}}`
  * `${{CLOUDSQL_INSTANCE}}`

## Helpers

This boot script installs a couple of helpers which can be accessed from within the VM:

* [`rails`](RAILS.md) - helps starting docker containers
* `console` - Start a Rails console
* `project_id` - Returns the VM's project
* `access_token` - Returns a Access Token
* `fetch_secret <secret>` - Fetches a secret from the Secret Manager
* [`jq`](https://stedolan.github.io/jq/) - Parses JSON.


## Release

```
make build # will build dist/cloud-init.yml
```

## Debugging

SSH into a machine that was started with this cloud-init file and you'll 
find the following commands useful for debugging:

```
sudo journalctl -f
cat /var/log/rails-cmd.log 
tail -n100 -f /var/log/cloud-init-output.log
```

## References

* [Container Optimized OS Filesystem](https://cloud.google.com/container-optimized-os/docs/concepts/disks-and-filesystem)

