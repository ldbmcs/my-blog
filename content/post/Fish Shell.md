+++
title="Fish Shell"
date="2022-07-20"
tags=["Shell"]
+++

[fish](https://fishshell.com/) is a fully-equipped command line shell (like bash or zsh) that is smart and user-friendly. Fish supports powerful features like syntax highlighting, autosuggestions, and tab completions that just work, with nothing to learn or configure.

## 1. Install

### 1.1 macOS

```shell
brew install fish
```

### 1.2 CentOS

For **CentOS 8** run the following as **root**:

```shell
cd /etc/yum.repos.d/
wget https://download.opensuse.org/repositories/shells:fish:release:3/CentOS_8/shells:fish:release:3.repo
yum install -y fish
```

For **CentOS 7** run the following as **root**:

```shell
cd /etc/yum.repos.d/
wget https://download.opensuse.org/repositories/shells:fish:release:3/CentOS_7/shells:fish:release:3.repo
yum install -y fish
```

## 2. Starting and Exiting

Once fish has been installed, open a terminal. If fish is not the default shell:

- Type **fish** to start a shell:

  ```shell
  fish
  ```

- Type **exit** to end the session:

  ```shell
  exit
  ```

## 3. Change Default Shell

To change your login shell to fish:

1. Add the shell to `/etc/shells` with:

   ```shell
   echo /usr/local/bin/fish | sudo tee -a /etc/shells
   ```

2. Change your default shell with:

   ```shell
   chsh -s $(which fish)
   ```

Again, substitute the path to fish for `/usr/local/bin/fish` - see `command -s fish` inside fish. To change it back to another shell, just substitute `/usr/local/bin/fish` with `/bin/bash`, `/bin/tcsh` or `/bin/zsh` as appropriate in the steps above.

## 4. Uninstalling fish

If you want to uninstall fish, first make sure fish is not set as your shell. Run `chsh -s /bin/bash` if you are not sure.

If you installed it with a package manager, just use that package manager’s uninstall function. If you built fish yourself, assuming you installed it to /usr/local, do this:

```
rm -Rf /usr/local/etc/fish /usr/local/share/fish ~/.config/fish
rm /usr/local/share/man/man1/fish*.1
cd /usr/local/bin
rm -f fish fish_indent
```

## 6. Configuration

To store configuration write it to a file called `~/.config/fish/config.fish`.

`.fish` scripts in `~/.config/fish/conf.d/` are also automatically executed before `config.fish`.

These files are read on the startup of every shell, whether interactive and/or if they’re login shells. Use `status --is-interactive` and `status --is-login` to do things only in interactive/login shells, respectively.

This is the short version; for a full explanation, like for sysadmins or integration for developers of other software, see [Configuration files](https://fishshell.com/docs/current/language.html#configuration).

### 6.1 fish_config - start the web-based configuration interface

`fish_config` is used to configure fish.

### 6.2 alias

```shell
alias rmi="rm -i"

# This is equivalent to entering the following function:
function rmi --wraps rm --description 'alias rmi=rm -i'
    rm -i $argv
end

# This needs to have the spaces escaped or "Chrome.app..."
# will be seen as an argument to "/Applications/Google":
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome banana'
```

### 6.3 set - display and change shell variables

```shell
# Prints all global, exported variables.
set -xg

# Sets the value of the variable $foo to be 'hi'.
set foo hi

# Appends the value "there" to the variable $foo.
set -a foo there

# Does the same thing as the previous two commands the way it would be done pre-fish 3.0.
set foo hi
set foo $foo there

# Removes the variable $smurf
set -e smurf

# Changes the fourth element of the $PATH list to ~/bin
set PATH[4] ~/bin

# Outputs the path to Python if ``type -p`` returns true.
if set python_path (type -p python)
    echo "Python is at $python_path"
end

# Setting a variable doesn't modify $status!
false
set foo bar
echo $status # prints 1, because of the "false" above.

true
set foo banana (false)
echo $status # prints 1, because of the "(false)" above.

# Like other shells, pass a variable to just one command:
# Run fish with a temporary home directory.
HOME=(mktemp -d) fish
# Which is essentially the same as:
begin; set -lx HOME (mktemp -d); fish; end
```

## 7. Commands

### 7.1 [set](https://fishshell.com/docs/current/cmds/set.html#cmd-set) - display and change shell variables

```shell
set [SCOPE_OPTIONS]
set [OPTIONS] VARIABLE VALUES ...
set [OPTIONS] VARIABLE[INDICES] VALUES ...
set (-q | --query) [SCOPE_OPTIONS] VARIABLE ...
set (-e | --erase) [SCOPE_OPTIONS] VARIABLE ...
set (-e | --erase) [SCOPE_OPTIONS] VARIABLE[INDICES] ...
set (-S | --show) VARIABLE ...
```

**How to set global environment-variables**：Use [Universal Variables](https://fishshell.com/docs/current/tutorial.html#universal-variables)

```shell
set -Ux VARIABLE VALUES
```

Do not append to universal variables in `config.fish` file, because these variables will then get longer with each new shell instance. Instead, simply run set `-Ux` once at the command line.

Universal variables will be stored in the file `~/.config/fish/fish_variables` as of Fish 3.0

### 7.2 [history](https://fishshell.com/docs/current/cmds/history.html#history-show-and-manipulate-command-history) - show and manipulate command history

```shell
history [search] [--show-time] [--case-sensitive]
                 [--exact | --prefix | --contains] [--max N] [--null] [--reverse]
                 [SEARCH_STRING ...]
history delete [--case-sensitive]
               [--exact | --prefix | --contains] SEARCH_STRING ...
history merge
history save
history clear
history clear-session
```

## 8. [fisher](https://github.com/jorgebucaran/fisher): A plugin manager for [Fish](https://fishshell.com/)

### 5.1 Installation

```shell
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
```

### 5.2 [Install Dracula theme](https://draculatheme.com/fish)

```shell
fisher install dracula/fish
```

### 5.3 [Install SDKMAN](https://github.com/reitzig/sdkman-for-fish)

```shell
fisher install reitzig/sdkman-for-fish@v1.4.0
```

### 5.4 [Install NVM](https://github.com/jorgebucaran/nvm.fish)

```shell
fisher install jorgebucaran/nvm.fish
```