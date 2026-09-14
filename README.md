# ansible
This repository covers the ansible playbook for my desktop and home server configuration and maintenance.
- [design principles](#design-principles)
  - [concepts](#concepts)
  - [role division](#role-division)
  - [role dependency](#role-dependency)
- [playbook breakdown](#playbook-breakdown)
  - [`network`](#network)
  - [`packages`](#packages)
  - [`file-sync`](#file-sync)
  - [`git-repos`](#git-repos)
  - [`config`](#config)
  - [`services`](#services)
## design principles
This section covers the ideas behind the playbook and their implementation.
### concepts
- *synchronization*
  - the playbook is meant to run on both hosts simultaneously
  - cross-host dependencies and their order need to be handled accordingly
- *idempotence*
  - the playbook is meant for initial setup, maintenance and potential reconfiguration of the host state
  - it should run smoothly for all of those use cases
- *swiftness*
  - the playbook is meant to be ran often, and hence should not add time overhead
  - simple maintenance changes, like adding a new package to be installed, should require minimal time and code
  - introducing those changes should then run the smallest possible number of tasks in the least possible amount of time
  - for the above reasons roles are not split by features, but rather by the type of work being done
- *privacy and security*
  - a lot of information is not necessary to track with `git`:
    - stuff like list of packages or synced file directories, for privacy reasons
    - stuff like credentials or infrastructure details, for security reasons
    - stuff that can dynamically change with no significance for the playbook architecture, like all of the above examples
  - for that reason certain files are symlinked outside of the repository
### role division
Role split can be explained with the example of adding a new service to run on a host:

A typical setup could be a singular role that:
- pulls the appropriate package
- handles all config files
- starts the service

What is done here instead is instead integrating each of those steps into their respective roles:
- add a package to the system package list (pulled in the `packages` role)
- add a config file task to the `config` role
- add a service to the list of system services (started in the `services` role)

This solution:
- reduces time overhead for task execution
- reduces the amount of code when adding changes

at the expense of a logical spread - might be slightly harder to search for specific tasks or decide where to put them.

### role dependency
Due to the desired swiftness of playbook usage, there are no role dependencies configured.

The point of granular roles is to be able to run them selectively as necessary, without sourcing other roles that would take a significant amount of time to throw a wall of `ok` statuses.

Dependency is instead handled with order - each role comes at a point in playbook where everything it requires should already have been set up by the previous roles.

Speaking in real use cases: the initial run should include the entire playbook to ensure nothing breaks, after that selective roles are fine.

## playbook breakdown
Here's the general breakdown of the current playbook state, role by role
> It's assumed the playbook is always run from the desktop host.
### network
A basic network setup role.
- ensure a functional network connection
- enable the firewall
- configure `/etc/hosts` and `ssh`
### packages
A role to install and update the desired packages from all necessary sources:
- system package manager
- flatpak
- AUR

Logs from those are saved if anything changed, then printed at the end of the playbook.

This allows for better readability than enabling verbose logging for the whole playbook.
### file-sync
A role to configure file synchronization and backups.
> This is the only role that requires manual setup on the first run. \
> If the home server is not synced to the remote backup, you need to do that on your own. \
> There are several reasons for that, the biggest ones being file transfer progress tracking and idempotency issues.
- check for the remote backup marker
  - throw an error if it's not there
- set up a remote backup cronjob
- pull desired directories from the home server to the desktop
- symlink `.stignore` files

This role only really needs running on the initial setup, since after that `syncthing` takes over. \
That's why it's configured to be mostly skipped if everything is in place.

### git-repos
Possibly the most interesting role here, one I spent most time polishing up and the best showcase of cross-host dependencies.

Some architectural introduction here:
- we have a list of `git` repositories that live on the desktop
  - github serves as the primary remote
  - home server is the secondary one, serving as the backup
- the home server also uses some of those repositories
  - would make no sense to add network overhead, so it pulls from itself

The idea of the role is to ensure a full sync across all of those.

We want the remotes to be dynamically updated during each run, depending on the conditions:
- if the primary remote is inaccessible for any reason, the desktop should switch to using backup as the primary
- if it later becomes accessible, the config should be updated accordingly
- if the remote path changes for any reason, it should be reflected in all affected repositories
- if anything was changed manually but not configured in ansible, it should be overridden

> Note that the `git` module is too simplistic for some tasks in this role, that's why shell was used.

> Also note that this role only runs for the current branch on each repository. This is enough for my needs at the moment.

The course of the role is as follows:
- check for github access on the desktop
- clone all non-existing repos on both hosts
- setup or reconfigure remotes for all repositories on both hosts, according to the logic described before
- pull all repositories on the desktop (except this one, in case we're still testing)
- push from desktop to all available remotes
- pull all repositories on the home server

The repository-specific tasks iterate over a full list. This solution is both faster and more readable than iterating over all tasks for each repo subsequently.

### config
A generic role for configuration of various stuff.

Doesn't really make sense to describe since the content might change dynamically.

The most important part here is the `zsh` and `nvim` setup.

### services
A role for system service management.
- configure the `ufw` rules
  - reload `ufw` if anything changed
  - this is done here and not in the network role because some named `ufw` rules come with specific packages
- enable all desired `systemd` services
