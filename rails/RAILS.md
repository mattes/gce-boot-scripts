# rails command

`rails` is available as helper inside the VM. It helps with the creation of docker containers,
launching containers in read-only mode.

## Usage

Start a Rails console:  
(Please note that you can also just type `console` to start a Rails console)

```
rails --interactive --service console --run 'rails console' 
```

Start Rails app:

```
rails --service my-app --run 'rails server -b 0.0.0.0 -p 8080' --port 8080 -e RAILS_SERVE_STATIC_FILES=true
```

Start two workers on a Virtual Machine:

```
rails --service worker --container worker-1 --run 'rails jobs:work' --graceful-shutdown 60
rails --service worker --container worker-2 --run 'rails jobs:work' --graceful-shutdown 60
```

## Options

| Option                    | Description                                                                                                                                |
|---------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| -i --interactive          | Runs container interactive, attaching a tty.                                                                                               |
| -c --container=[name]     | The name of the container, defaults to --service.                                                                                          |
| -s --service=[name]       | The service name, sets `SERVICE` ENV var inside container.                                                                                 |
| -p --port=[port]          | Instruct iptables to allow traffic on this port.                                                                                           |
| -e --env=[key=value]      | Set ENV variables.                                                                                                                         |
| -r --run=[cmd]            | The command to run inside the container.                                                                                                   |
| --stop-signal=[signal]    | Stop signal to send during shutdown, i.e. SIGQUIT. Default is SIGTERM.                                                                     |
| --healthcheck-port=[port] | Start [healthcheck helper](https://github.com/mattes/healthcheck-cmd) on port.                                                             |
| --graceful-shutdown=[sec] | Start [graceful-shutdown helper](https://github.com/mattes/gce-graceful-shutdown) to enable graceful shutdowns for long running processes. |
| --dry-run                 | Only print, don't execute anything.                                                                                                        |
| -h --help                 | Help text                                                                                                                                  |
| --verbose                 | Verbose output                                                                                                                             |

