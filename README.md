[![Build Status](https://travis-ci.org/andeman/puppet-foreman_hammer.svg?branch=master)](https://travis-ci.org/andeman/puppet-foreman_hammer.svg?branch=master)
[![Puppet Forge](https://img.shields.io/puppetforge/v/andeman/foreman_hammer.svg)](https://forge.puppetlabs.com/andeman/foreman_hammer)
[![Puppet Forge Downloads](http://img.shields.io/puppetforge/dt/andeman/foreman_hammer.svg)](https://forge.puppetlabs.com/andeman/foreman_hammer)

# foreman_hammer

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with foreman_hammer](#setup)
    * [What foreman_hammer affects](#what-foreman_hammer-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with foreman_hammer](#beginning-with-foreman_hammer)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module includes Bolt task and plans for managing hosts in foreman with hammer-cli. Sensitive information like the 
foreman password could be encrypted as a bolt secret and read from inventory.yaml. Multiple host can be generated from
yaml templates.

More information about foreman: https://theforeman.org/

More information about hammer-cli: https://github.com/theforeman/hammer-cli

## Setup

### Requirements
The Bolt target host requires:

* [python3](https://wiki.python.org/moin/BeginnersGuide/Download)
* [PyYAML](https://pypi.org/project/PyYAML/)
* [hammer-cli-foreman](https://github.com/theforeman/hammer-cli-foreman)

### Install requirements
For examples on how to install the needed requirements look at the acceptance test setup file [spec/spec_helper_acceptance_local.rb](spec/spec_helper_acceptance_local.rb).

### Beginning with foreman_hammer

There a different parts to setup the module.

#### foreman host templates
A foreman host template is written in YAML and provides information on how to build the hammer-cli command for the 
host using this template.

There a 2 basic rules:

1. YAML scalars create hammer-cli command options
2. YAML maps create parameters which are comma-separated list of key=value pairs

To create a host named `test-host` you can specify the following host template:

```
---
hostgroup: my_hostgroup
compute-resource: libvirt
compute-attributes:
  cpus: 2
interface:
  - primary: true
    compute_type: network
    compute_network: default
volume:
  - capacity: 5G
  - capacity: 10G
    format_type: qcow2
```

and the following hammer-cli command will be used for creating the host:

```
hammer host create
  --hostgroup=my_hostgroup                   # most of the settings is done in the hostgroup
  --compute-resource=libvirt                 # set the libvirt provider
  --compute-attributes="cpus=2"              # specify the provider specific options, see the list below
  --interface="primary=true,compute_type=network,compute_network=default" # add a network interface, can be passed multiple times
  --volume="capacity=5G"                     # add a volume, can be passed multiple times
  --volume="capacity=10G,format_type=qcow2"  # add another volume with different size and type
  --name="test-host" 
```

See the following example as a base for building your own foreman host templates: [data/host_templates/centos7.yaml](data/host_templates/centos7.yaml)


#### hiera
The Bolt plans in this module will lookup the configuration **how to manage hosts** using hiera.

It specifies a list of host which will be managed and the unique information needed for each host e.g. ip, cpu, mem, 
the foreman host template etc..

See all available options in [data/common.yaml](data/common.yaml).

For a example look at [examples/example_common.yaml](examples/example_common.yaml)

#### inventory.yaml
The Bolt plans in this module will lookup the configuration **how to access foreman** with Bolt inventory file variables.

For an example look at [examples/inventory.yaml.dist](examples/inventory.yaml.dist)

## Usage

This example should show the basic usage of the included bolt plans. 

For detailed instructions about the bolt task and plans look at [REFERENCE.md](REFERENCE.md).

### Examples

This Bolt plan will create nonexistent host and update existing ones in foreman.

Create a bolt secret key pair for encrypting secrets (will not overwrite existing ones):

```
bolt secret createkeys
```

Generate example inventory.yaml:
```
./examples/generate_inventory
```

Provide the required infos for the script:
```
Generating inventory: ./examples/inventory.yaml from template: ./examples/inventory.yaml.dist
Backup existing inventory to: ./examples/inventory.yaml.2020-08-05_16:02:50
Please enter your value for <FOREMAN_URL>: https://foreman.example.de/
Please enter your value for <FOREMAN_USERNAME>: admin
Please enter your value for <SECRET_FOREMAN_PASSWORD>: ***********
```

This will produce this inventory.yaml:
```
# Inventory file for Bolt
version: 2
groups:
  - name: hammer-local
    targets:
      - hammer-local.127.0.0.1.nip.io
    config:
      transport: local
    vars:
      foreman:
        server_url: "https://foreman.example.de/"
        hammer_cli_bin: "hammer"
        username: 'admin'
        password:
          _plugin: pkcs7
          encrypted_value: ENC[PKCS7,MIIBiQYJFoZIhvcNAQcDoIIBeDDAXYCAQAxggEhMIIBHQIBADAFMAA.................==]

```

Execute the  bolt plan on localhost and connect the foreman api with hammer-cli:

```
bolt plan run foreman_hammer::hosts -i examples/inventory.yaml --target hammer-local --hiera-config examples/hiera.yaml
```

The following files will be used for the configuration of the bolt plan:

- foreman host template: [data/host_templates/centos7.yaml](data/host_templates/centos7.yaml)
- hiera configuration [examples/example_common.yaml](examples/example_common.yaml)
- foreman access credentials: [examples/inventory.yaml](examples/inventory.yaml)

Please adapt the examples to work with your individual foreman setup.

Happy automating!

## Limitations

See [metadata.json](metadata.json)

## Know Issues

### Fetch missing ca certificate for foreman
CA Certificate for foreman server specified in `server_url` in inventory.yaml is missing:
```
Failed on hammer-local.127.0.0.1.nip.io:
  Could not load the API description from the server: SSL certificate verification failed
  Make sure you configured the correct URL and have the server's CA certificate installed on your system.
  
  You can use hammer to fetch the CA certificate from the server. Be aware that hammer cannot verify whether the certificate is correct and you should verify its authenticity after downloading it.
  
Download the certificate as follows:

  $ hammer --fetch-ca-cert https://foreman.example.de/
```

Solution:

Fetch the certificate with the hammer binary specified in `hammer_cli_bin`
```
hammer --fetch-ca-cert https://foreman.example.de/
```

## Development

### Running acceptance tests
To run the acceptance tests you can use Puppet Litmus [https://puppetlabs.github.io/litmus/](https://puppetlabs.github.io/litmus/).

Install needed requirements:

https://puppetlabs.github.io/litmus/Running-acceptance-tests.html

Create test environment:
```
./scripts/create_test_env
```

Run the acceptance tests:
```
./scripts/run_tests
```

Remove the test environment:
```
./scripts/remove_test_env
```

**Optional**

Run the tests only on one machine:
```
./scripts/run_vm_test 2222
```

Run only one test on one machine:
```
scripts/run_single_test spec/acceptance/tasks/create_host_spec.rb 2222
```

Create the test env for e.g. ubuntu - see [provision.yaml](provision.yaml)
```
scripts/create_test_env travis_ub
```

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

All contributions must pass all existing tests, new features should provide additional unit/acceptance tests.
