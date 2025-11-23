# SSH Configuration

This document is licensed under the terms of the [GNU Free Documentation License 1.3 or later](https://www.gnu.org/copyleft/fdl.html).

## Initial Setup

Basic setup:

```sh
mkdir ~/.ssh
ssh-keyscan github.com >>~/.ssh/known_hosts
touch ~/.ssh/config
```

Create default key:

```sh
eval (ssh-agent -c)
ssh-keygen -t ed25519
ssh-add
cat ~/.ssh/id_ed25519.pub
```

The public key printed in the last step can then be added on GitHub, but only to one account, and elsewhere.

## Additional Keys

Additional keys can be generated as follows, where `<email>` is the email stored in the key and `<id_name>` is the name of the key, which should start with `id_`:

```sh
eval (ssh-agent -c)
ssh-keygen -t ed25519 -C <email> -f ~/.ssh/<id_name>
ssh-add ~/.ssh/<id_name>
cat ~/.ssh/id_rsa_kurbo96.pub
```

The public key printed in the last step can then be used where needed.

### Use with Git

In normal situations (i.e. only one account with the same host), the following is enough:

```sh
echo -e "Host <host>\n  User <username>\n  IdentityFile ~/.ssh/<id_name>" >>~/.ssh/config
```

For example, for the AUR, the host is `<aur.archlinux.org>` and the username is `aur`.

### Multiple GitHub Accounts

Since each SSH key can be used for at most one GitHub account, a different key has to be used for each account.
For Git to use the right key, some trickery is required:

```sh
echo -e "Host github-<username>\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/<id_name>" >>~/.ssh/config
echo -e "[url \"git@github-<username>:<username>\"]\n\tinsteadOf = git@github.com:<username>" >>~/.gitconfig
```
