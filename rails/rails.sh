#!/bin/bash
args=("$@")
interactive=false
container=
service=
port=
envs=()
run=
healthcheck_port=
graceful_shutdown_sec=
stop_signal="SIGTERM"
dry_run=false
help=false
verbose=false

while :; do
  case $1 in
    -i|--interactive) interactive=true;;
    -c|--container) container=$2; shift;;
    -s|--service) service=$2; shift;;
    -p|--port) port=$2; shift;;
    -e|--env) envs+=("${2%=*}='${2#*=}'"); shift;;
    -r|--run) run=$2; shift;;
    --stop-signal) stop_signal=$2; shift;;
    --healthcheck-port) healthcheck_port=$2; shift;;
    --graceful-shutdown) graceful_shutdown_sec=$2; shift;;
    --dry-run) dry_run=true;;
    -h|--help) help=true;;
    --verbose) verbose=true;;
    --) shift; break;;
    -?*) printf 'WARN: Ignored unknown option: %s\n' "$1" >&2;;
    *) break
  esac
  shift
done

if $help; then
  echo "Please visit https://github.com/mattes/gce-boot-scripts/blob/master/rails/RAILS.md for help."
  exit 0
fi

mountopts() {
  local size=$1
  echo "noexec,mode=770,size=$size,uid=65534,gid=65534"
}

die() {
  echo $1; exit 1
}

if [[ -z "$container" ]]; then container=$service; fi
if [[ -n $healthcheck_port && $interactive == true ]]; then die "--healthcheck-port can't be used in --interactive mode"; fi
if [[ -n $graceful_shutdown_sec && $interactive == true ]]; then die "--graceful-shutdown can't be used in --interactive mode"; fi

container=${container//[^a-zA-Z0-9]/_} # replace non-ascii with underscore

cmd=("docker run")
cmd+=("-e SERVICE='$service'")
if ! $interactive; then
  cmd+=("--name='$container'")
  cmd+=("--detach")
  cmd+=("--log-driver=gcplogs")
  cmd+=("--restart=on-failure")
  cmd+=("--cidfile='/var/run/pids/$container.cid'")
else
  cmd+=("--interactive") 
  cmd+=("--tty") 
  cmd+=("--rm") 
  cmd+=("-e RAILS_LOG_TO_STDOUT=true")
fi
cmd+=("${envs[@]/#/-e }")
cmd+=("-e GOOGLE_SECRETS_PREFIX='${{SECRETS_PREFIX}}'")
cmd+=("--net=host")
cmd+=("--stop-signal='$stop_signal'")
cmd+=("--read-only")
cmd+=("--tmpfs=/tmp:`mountopts 1G`")
cmd+=("--tmpfs=/app/tmp:`mountopts 1G`")
cmd+=("--tmpfs=/app/tmp/cache:`mountopts 1G`")
cmd+=("--tmpfs=/app/tmp/pids:`mountopts 10M`")
cmd+=("--tmpfs=/app/storage:`mountopts 1G`")
cmd+=("${{DOCKER_IMAGE}}")
cmd+=("$run")

prettyOut="$(printf '%s \\\n  '  "${cmd[@]}")"
prettyOut="${prettyOut%\\*}"
if $dry_run || $verbose; then echo "$prettyOut"; fi

if ! $dry_run; then 
  # write rails cmd log
  echo "rails ${args[@]}" >> /var/log/rails-cmd.log # BUG: preserve arg's quotes
  echo -e "$prettyOut\n" >> /var/log/rails-cmd.log

  # start container and open port
  eval "${cmd[@]}"
  if [[ -n $port ]]; then
    sudo iptables -w -A INPUT -p tcp --dport "$port" -j ACCEPT
  fi

  if [[ -n $healthcheck_port ]]; then
    # listen for healthchecks and check if container is running
    nohup healthcheck -listen "0.0.0.0:$healthcheck_port" -command "docker inspect '$container' --format '{{json .State.Status }}' | grep running" >> /var/log/cloud-init-output.log 2>&1 & echo $! > "/var/run/pids/$container-healthcheck.pid"
    sudo iptables -w -A INPUT -p tcp --dport "$healthcheck_port" -j ACCEPT
  fi

  if [[ -n $graceful_shutdown_sec ]]; then
    # First send --stop-signal to container, then wait for container to stop.
    # `docker wait` returns zero/ success status code if container stopped already or stops within --graceful-shutdown period.
    # If the container does not shut down within grace period, `docker wait` is killed and the container receives a SIGTERM signal.
    # After that it's up to the process in the container to wind things down. We don't send SIGKILL to the container
    # to give it time until the instance is eventually deleted by Google Cloud.
    nohup graceful-shutdown -timeout "${graceful_shutdown_sec}s" -on-shutdown "docker kill --signal '$stop_signal' '$container'; timeout --signal KILL ${graceful_shutdown_sec}s docker wait '$container' || docker kill --signal SIGTERM '$container'" >> /var/log/cloud-init-output.log 2>&1 & echo $! > "/var/run/pids/$container-graceful-shutdown.pid"
  fi
fi
