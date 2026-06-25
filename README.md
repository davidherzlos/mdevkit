# mdevkit

A local Moodle development environment built on top of
[moodle-docker](https://github.com/moodlehq/moodle-docker). The `mdev.sh`
script wraps the moodle-docker compose commands and adds helpers for
provisioning the webserver container (extra packages, Xdebug, Neovim, dotfiles)
so you can develop Moodle inside the container.

The Moodle branch, PHP version, database engine, and exposed port are all
configurable through `.env` (see [Configuration](#configuration)).

## Layout

| Path            | Description                                                       |
| --------------- | ----------------------------------------------------------------- |
| `mdev.sh`       | Main entry point — manage and provision the containers.           |
| `install.sh`    | Runs *inside* the webserver container to install dev tooling.     |
| `.env`          | Environment variables for moodle-docker (project, DB, PHP, port). |
| `dotfiles/`     | Config copied into the container (`config.php`, `local.yml`, …).  |
| `moodle/`       | Git submodule — the Moodle source code (served as wwwroot).       |
| `moodle-docker/`| Git submodule — the official moodle-docker tooling.               |

## Requirements

- Docker + Docker Compose
- Git (with SSH access to GitHub for the submodules)
- An SSH key configured for `git@github.com` (submodules use SSH URLs)

## Configuration

Settings live in `.env`. These map to the
[moodle-docker environment variables](https://github.com/moodlehq/moodle-docker#environment-variables),
so refer to that project for the full list of supported values:

```sh
COMPOSE_PROJECT_NAME=...        # docker compose project name
MOODLE_DOCKER_WWWROOT=...       # path to Moodle source (the submodule)
MOODLE_DOCKER_PHP_VERSION=...   # PHP version for the webserver
MOODLE_DOCKER_DB=...            # database engine (pgsql, mariadb, mysql, …)
MOODLE_DOCKER_WEB_PORT=...      # host port the site is exposed on
INTELEPHENSE_LICENSE_DIR=...    # path to your Intelephense license(custom var used in local.yml)
```

Adjust these before first launch to customize the PHP version, database engine,
port, and so on.

## Container customization (`local.yml`)

moodle-docker's official override mechanism: definitions in `local.yml` are
merged on top of the base config. `./mdev.sh up` copies `dotfiles/local.yml`
into `moodle-docker/` so it's picked up. The current file customizes the
**webserver** container to:

- Mount the Intelephense license (from `INTELEPHENSE_LICENSE_DIR`).
- Share the host SSH agent (`$SSH_AUTH_SOCK`) so in-container `git` uses your keys.
- Provision `~/.ssh/config` into the container via a custom entrypoint.

## Quick start

```sh
# 1. Clone the repo (submodules are initialized later by `up`)
git clone git@github.com:davidherzlos/mdevkit.git      # SSH
# git clone https://github.com/davidherzlos/mdevkit.git  # HTTPS
cd mdevkit

# 2. Review and adjust .env for your machine (PHP version, DB, port, license path)
$YOUREDITOR .env

# 3. Build and start the containers (also inits submodules + copies local.yml)
./mdev.sh up

# 4. Provision dev tooling inside the webserver container
./mdev.sh setup

# 5. Install the Moodle database (creates the admin user + PHPUnit if present)
./mdev.sh install
```

After `install`, the site is available at `http://localhost:<MOODLE_DOCKER_WEB_PORT>`
— with the default `.env` that is <http://localhost:8080>.

Default admin credentials created by `install`:

- **username:** `admin`
- **password:** `test`
- **email:** `admin@mailinator.com`

Day to day, use `stop`/`start` to pause and resume the containers, and `down`
to tear everything down:

```sh
./mdev.sh stop      # pause work
./mdev.sh start     # resume work
./mdev.sh down      # tear everything down
```

## What `setup` installs

`./mdev.sh setup` copies `install.sh` + `dotfiles/` into the webserver container
and runs the script. The base moodle-docker image only ships PHP + Apache, so
the script layers on everything needed to actually develop Moodle from inside
the container, grouped by purpose:

- **PHP debugging & analysis** — Xdebug (step debugging) plus, via Composer,
  the Moodle coding standards (`moodle-cs`), `phpstan-moodle` (static analysis),
  and PsySH (interactive REPL). The matching `phpstan.neon` and PsySH dotfiles
  are dropped in alongside Moodle's `config.php`.
- **Frontend build chain** — `nvm` + the Node version Moodle pins, npm
  dependencies, and `grunt-cli`, which Moodle uses to compile its JS/AMD and
  SCSS assets.
- **Database client** — `postgresql-client`, so you can reach the `db`
  container with `psql` from a shell.
- **Editor** — a pinned Neovim build with the
  [moodle-nvim](https://github.com/davidherzlos/moodle-nvim) config, plus its
  native dependencies: `cmake`/`make`/`gcc`/`luarocks` to compile plugins and
  tree-sitter parsers, `ripgrep`/`fd` for in-editor search, and `watchman` for
  file watching. A `.gitconfig` is fetched too.
- **CLI AI tools** — Claude Code, OpenCode, Auggie, and `tree-sitter-cli`.

## Commands

Run `./mdev.sh <command>`:

| Command             | What it does                                                        |
| ------------------- | ------------------------------------------------------------------- |
| `up`                | Init submodules, copy `local.yml`, create and start the containers. |
| `down`              | Stop and remove the containers.                                     |
| `start`             | Start existing (stopped) containers.                                |
| `stop`              | Stop the containers without removing them.                          |
| `restart_webserver` | Restart just the webserver container.                               |
| `setup`             | Copy `install.sh` + `dotfiles` into the webserver and run installer.|
| `install`           | Initialize the Moodle DB and (if present) PHPUnit.                  |
| `nvim_refresh`      | Reset and re-copy your `~/.config/nvim` if available, into the container.         |

Running `./mdev.sh` with no (or an unknown) argument prints the usage summary.
