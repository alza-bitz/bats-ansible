# bats-ansible

`bats-ansible` is a helper library providing useful functions for
testing [Ansible][ansible] roles using [Bats][bats].

These functions allow the creation of Bats test suites with
the following features:

- Start one or more containers that will form your test inventory.
- Apply the role under test to some or all of the inventory, using
your test playbook definitions.
- Make state-based verifications on the inventory, using the functions
provided, in combination with standard Bats assertion techniques or with
the third-party [bats-assert][bats-assert] library instead.
- Clean up the test inventory at the end of the test.

## Example

A simple example best illustrates the intended use. The following example
includes some tests for a ficticious Ansible role named `somerole`.

**tests/test.yml**:
```yaml
- hosts: container
  remote_user: test

  roles:
    - somerole
```

**tests/ansible.cfg**:
```ini
[defaults]
roles_path = ../../
```

**tests/somerole-container.bats**:
```bash
#!/usr/bin/env bats

load 'bats-ansible/load'

setup() {
  container=$(container_startup fedora)
  hosts=$(tmp_file $(container_inventory $container))
}

@test "Role can be applied to container" {
  ansible-playbook -i $hosts test.yml
}

@test "Role is idempotent" {
  run ansible-playbook -i $hosts test.yml
  run ansible-playbook -i $hosts test.yml
  [[ $output =~ changed=0.*unreachable=0.*failed=0 ]]
}

teardown() {
  container_cleanup $container
}
```

## Dependencies
- [Docker][docker] for the containers in the test inventory.
- [Ansible][ansible] for applying the role under test; it is also directly
required by some helper functions.
- [Bats][bats] itself for executing tests that make use of the library.

## Installation

There are multiple supported installation methods. One may be better
than the others depending on your case.

### Git submodule

If your Ansible role project uses Git, the recommended method of installation is via
a [submodule][git-book-submod].

*__Note:__ The following example installs libraries in the
`./tests` directory of your Ansible role.*

```sh
$ git submodule add https://github.com/alzadude/bats-ansible tests/bats-ansible
$ git commit -m 'Add bats-ansible library'
```

### Git clone

If you do not use Git for your role project, simply [clone][git-book-clone] the repository.

*__Note:__ The following example installs libraries in the
`./tests` directory of your Ansible role.*

```sh
$ git clone https://github.com/alzadude/bats-ansible tests/bats-ansible
```

## Loading

A library is loaded by sourcing the `load.bash` file in its main
directory.

Assuming that libraries are installed in the `tests` directory of your Ansible
role, adding the following line to a file in the `tests` directory will load the
`bats-ansible` library.

```sh
load 'bats-ansible/load'
```

*__Note:__ The [`load`][bats-load] function sources a file (with
`.bash` extension automatically appended) relative to the location of
the current test file.*

If a library depends on other libraries, they must be loaded as well.


## Usage

### `container_startup`

Start a container of the given type and 'host' name, and emit pipe-separated
container details to stdout.

If not given, the 'host' name of the container (for Ansible inventory purposes)
defaults to `container`.

Fails if the given container type is invalid, or if the container could not be started
for some reason.

```bash
setup() {
  container=$(container_startup fedora)
}
```

On failure, the currently running test will fail and an error message concerning
the cause of the failure will be displayed.

### `container_cleanup`

### `container_inventory`

### `container_exec`

### `container_exec_sudo`

### `container_exec_module`

### `container_dnf_conf`

<!-- REFERENCES -->

[bats]: http://github.com/sstephenson/bats
[ansible]: http://www.ansible.com
[bats-assert]: http://github.com/ztombol/bats-assert
[docker]: http://docker.com
[git-book-submod]: https://git-scm.com/book/en/v2/Git-Tools-Submodules
[git-book-clone]: https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository#Cloning-an-Existing-Repository
[bats-load]: https://github.com/sstephenson/bats#load-share-common-code
