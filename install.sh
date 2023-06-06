#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312

set -u

GIT_REMOTE=https://github.com/seguri/infra
INFRA_REPOSITORY=/opt/infra
INSTALL=("/usr/bin/install" -d -o "root" -g "root" -m "0755")

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
if [[ -z $BASH_VERSION ]]; then
  abort "Bash is required to interpret this script."
fi

# Check if both `INTERACTIVE` and `NONINTERACTIVE` are set
# Always use single-quoted strings with `exp` expressions
# shellcheck disable=SC2016
if [[ -n ${INTERACTIVE-} && -n ${NONINTERACTIVE-} ]]; then
  abort 'Both `$INTERACTIVE` and `$NONINTERACTIVE` are set. Please unset at least one variable and try again.'
fi

# Check if script is run in POSIX mode
if [[ ${POSIXLY_CORRECT+1} ]]; then
  abort 'Bash must not run in POSIX mode. Please unset POSIXLY_CORRECT and try again.'
fi

# Check if script is run non-interactively (e.g. CI)
# If it is run non-interactively we should not prompt for passwords.
# Always use single-quoted strings with `exp` expressions
# shellcheck disable=SC2016
if [[ ${NONINTERACTIVE-} ]]; then
  echo 'Running in non-interactive mode because `$NONINTERACTIVE` is set.'
else
  if [[ ${CI-} ]]; then
    echo 'Running in non-interactive mode because `$CI` is set.'
    NONINTERACTIVE=1
  elif [[ ! -t 0 ]]; then
    if [[ ${INTERACTIVE-} ]]; then
      echo 'Running in interactive mode despite `stdin` not being a TTY because `$INTERACTIVE` is set.'
    else
      echo 'Running in non-interactive mode because `stdin` is not a TTY.'
      NONINTERACTIVE=1
    fi
  fi
fi

unset IS_SUDO # unset this from the environment

is_sudo() {
  [[ -x /usr/bin/sudo ]] || return 1

  local -a SUDO=("/usr/bin/sudo")
  if [[ ${SUDO_ASKPASS-} ]]; then
    SUDO+=("-A")
  elif [[ ${NONINTERACTIVE-} ]]; then
    SUDO+=("-n")
  fi

  if [[ -z ${IS_SUDO-} ]]; then
    if [[ ${NONINTERACTIVE-} ]]; then
      "${SUDO[@]}" -l mkdir &>/dev/null
    else
      "${SUDO[@]}" -v && "${SUDO[@]}" -l mkdir &>/dev/null
    fi
    IS_SUDO="$?"
  fi

  (( IS_SUDO )) && abort "User needs to be an administrator!"

  return $IS_SUDO
}

# Search for the given executable in PATH (avoids a dependency on the `which` command)
which() {
  # Alias to Bash built-in command `type -P`
  type -P "$@"
}

# Search PATH for the specified program that satisfies Homebrew requirements
# function which is set above
# shellcheck disable=SC2230
find_tool() {
  [[ $# -eq 1 ]] || return 1

  local executable
  while read -r executable; do
    if [[ $executable != /* ]]; then
      echo "Ignoring $executable (relative paths don't work)"
    elif [[ -x $executable ]]; then
      echo "$executable"
      break
    fi
  done < <(which -a "$1")
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " %s" "${arg// /\ }"
  done
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

execute_sudo() {
  local -a args=("$@")
  if is_sudo; then
    if [[ ${SUDO_ASKPASS-} ]]; then
      args=("-A" "${args[@]}")
    fi
    echo "/usr/bin/sudo" "${args[@]}"
    execute "/usr/bin/sudo" "${args[@]}"
  else
    echo "${args[@]}"
    execute "${args[@]}"
  fi
}

# Invalidate sudo timestamp before exiting (if it wasn't active before).
if [[ -x /usr/bin/sudo ]] && ! /usr/bin/sudo -n -v 2>/dev/null; then
  trap '/usr/bin/sudo -k' EXIT
fi

(
  echo "Installing repository..."
  execute_sudo "${INSTALL[@]}" "$INFRA_REPOSITORY"
  cd "$INFRA_REPOSITORY" >/dev/null || return
  USABLE_GIT="$(find_tool git)"
  execute_sudo "$USABLE_GIT" "-c" "init.defaultBranch=master" "init" "--quiet"
  execute_sudo "$USABLE_GIT" "config" "remote.origin.url" "$GIT_REMOTE"
  execute_sudo "$USABLE_GIT" "config" "remote.origin.fetch" "+refs/heads/*:refs/remotes/origin/*"
  execute_sudo "$USABLE_GIT" "config" "--bool" "core.autocrlf" "false"
  execute_sudo "$USABLE_GIT" "config" "--bool" "core.symlinks" "true"
  execute_sudo "$USABLE_GIT" "fetch" "--force" "origin"
  execute_sudo "$USABLE_GIT" "fetch" "--force" "--force" "--tags" "origin"
  execute_sudo "$USABLE_GIT" "reset" "--hard" "origin/master"
) || exit 1

(
  echo "Installing ansible..."
  execute_sudo "apt" "update"
  execute_sudo "apt" "install" "ansible"
) || exit 1
