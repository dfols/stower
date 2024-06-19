# Stower

Stower is a tool designed to help you manage and organize your files using GNU Stow. It simplifies the process of creating symlinks for your files in a specified target directory while keeping the original files organized in a stow directory. Stower focuses solely on creating symlinks and does not support removing or modifying existing stows. Stower can be run in two modes: automatic mode using a configuration file, and manual mode.

## Automatic Mode (With configuration file)

In automatic mode, Stower reads a configuration file that specifies the stow directory, the target directory, the files to manage, and the package name for each package. This mode is suitable for managing multiple packages/applications at once.

### Example Configuration File

```ini
# Default stow directory
default_stow_dir=~/configurations

# Zsh configuration
[zsh]
files=~/.zshrc ~/.zprofile
target=~

# Neovim configuration
[nvim]
files=~/.config/nvim/init.vim ~/.config/nvim/coc-settings.json
target=~/.config/nvim
stow_dir=~/custom_stow

# Tmux configuration
[tmux]
files=~/.tmux.conf ~/.tmux.conf.local
target=~

# Git configuration
[git]
files=~/.gitconfig ~/.gitignore
target=~
```

### Running Stower in Automatic Mode

1. Clone the repository and navigate to the directory.
2. Make the `stower` script executable:
   ```bash
   chmod +x stower
   ```
3. Run Stower:
   ```bash
   ./stower
   ```
4. Select `1` for automatic mode.
5. Ensure a file named `stower_config` is in the current directory.
6. Stower will read the configuration file and process each package as specified.

## Manual Mode

In manual mode, Stower will guide you through the process of selecting the stow directory, the target directory, the files you want to manage, and the package name. This mode is suitable for managing a single package/application at a time.

### Steps in Manual Mode

1. **Select the stow directory**: Choose where your packages will be stored.
2. **Select the target directory**: Choose where symlinks to your packages will be created.
3. **Specify the files to manage**: Enter the paths of the files you want to manage.
4. **Specify the package name**: Enter a name for the package.

### Running Stower in Manual Mode

1. Clone the repository and navigate to the directory.
2. Make the `stower` script executable:
   ```bash
   chmod +x stower
   ```
3. Run Stower:
   ```bash
   ./stower
   ```
4. Select `2` for manual mode.
5. Follow the prompts to select the stow directory, target directory, files to manage, and package name.

## Contributing

Feel free to open issues and submit pull requests on the [GitHub repository](https://github.com/dfols/stower).
