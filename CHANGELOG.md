# Changelog

All notable changes to this project will be documented in this file.

## Release [1.0.0] - 2020-08-05
Initial Release

### Added

- Bolt plan `foreman_hammer::hosts`: if a hosts exists in foreman create it otherwise update. Show how to specify sensitive information via inventory.yaml.
- Bolt task `foreman_hammer::create_host`: creates a host with hammer_cli in foreman.
- Bolt task `foreman_hammer::update_host`: Update a host with hammer_cli in foreman with option to rebuild the host.
- Bolt task `foreman_hammer::get_host`: Get json infos with hammer_cli from foreman to use it in your own bolt plans.

