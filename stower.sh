#!/bin/bash

# Function to print a bordered message
print_border() {
    local msg=$1
    local border=""

    for ((i = 0; i < ${#msg}; i++)); do
        border+="="
    done

    echo "$border"
    echo "$msg"
    echo "$border"
}
# Function to display the main banner
display_banner() {
    cat <<"EOF"
       __                                       
      /\ \__                                    
  ____\ \ ,_\   ___   __  __  __     __   _ __  
 /',__\\ \ \/  / __`\/\ \/\ \/\ \  /'__`\/\`'__\
/\__, `\\ \ \_/\ \L\ \ \ \_/ \_/ \/\  __/\ \ \/ 
\/\____/ \ \__\ \____/\ \___x___/'\ \____\\ \_\ 
 \/___/   \/__/\/___/  \/__//__/   \/____/ \/_/ 
                                                
                                                
EOF
    echo
}

# Function to read and process the config file
read_config_file() {
    local config_file="$1"
    if [[ -f "$config_file" ]]; then
        local default_stow_dir=""
        local package_name=""
        local target_dir=""
        local files=""
        local package_stow_dir=""

        while IFS= read -r line || [[ -n "$line" ]]; do
            read_line "$line"
        done <"$config_file"

        # Process the last package section
        process_package_section
    else
        echo "Error: Configuration file $config_file does not exist."
        exit 1
    fi
}

# Function to parse and set the default stow_dir
parse_default_stow_dir() {
    local line="$1"
    if [[ "$line" =~ ^default_stow_dir=(.*)$ ]]; then
        default_stow_dir="${BASH_REMATCH[1]}"
        package_stow_dir="$default_stow_dir"
    fi
}

# Function to process each package section
process_package_section() {
    if [[ -n "$package_name" ]]; then
        stow_dir="$package_stow_dir"
        target_dir="$target_dir"
        files="$files"
        package_name="$package_name"

        move_files_to_package

        run_stow_command
        if [[ $? -eq 0 ]]; then
            stow_results+=("[$package_name]\n$target_dir <-- $stow_dir/$package_name\nSuccessfully stowed ✓")
        else
            stow_results+=("[$package_name]\n$target_dir <-- $stow_dir/$package_name\nError occurred while running stow for package: $package_name")
        fi

        # Reset package_stow_dir to default_stow_dir after processing
        package_stow_dir="$default_stow_dir"
    fi
}

# Function to read each line and delegate processing
read_line() {
    local line="$1"
    if [[ "$line" =~ ^default_stow_dir=(.*)$ ]]; then
        parse_default_stow_dir "$line"
    elif [[ "$line" =~ ^\[(.*)\]$ ]]; then
        process_package_section
        package_name="${BASH_REMATCH[1]}"
        package_stow_dir="$default_stow_dir" # Reset to default stow_dir for the new package
        target_dir=""
        files=""
    elif [[ "$line" =~ ^files=(.*)$ ]]; then
        files="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^target=(.*)$ ]]; then
        target_dir="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^stow_dir=(.*)$ ]]; then
        package_stow_dir="${BASH_REMATCH[1]}"
    fi
}

# Function to select the operation mode
select_operation_mode() {
    print_border "Please select how you would like to run Stower."
    echo "1) Use the stower_config file in the current directory"
    echo "2) Manually move files for a single package/application"
    echo

    read -r -p "Enter the number of your choice: " mode_choice
    if [[ "$mode_choice" == "1" ]]; then
        # Read and display the stower_config file
        read_config_file "./stower_config"
    elif [[ "$mode_choice" == "2" ]]; then
        echo "Proceeding with manual file move for a single package."
    else
        echo "Invalid choice. Please enter 1 or 2."
        exit 1
    fi
}

# Function to select the stow directory
select_stow_dir() {
    print_border "Please select the directory where your packages will be stored (the stow directory)."
    echo "1) Use the default configuration directory: ~/.config"
    echo "2) Specify a custom directory (relative to the current directory)"
    echo

    read -r -p "Enter the number of your choice: " stow_choice

    if [[ "$stow_choice" == "1" ]]; then
        stow_dir="$HOME/.config"
    elif [[ "$stow_choice" == "2" ]]; then
        read -r -p "Please enter the custom stow directory: " stow_dir
    else
        echo "Invalid choice. Please enter 1 or 2."
        exit 1
    fi

    # Expand tilde to home directory
    stow_dir=$(eval echo "$stow_dir")
    echo
    echo "Selected stow directory: $stow_dir"
    echo

    if [[ ! -d "$stow_dir" ]]; then
        echo "Creating directory: $stow_dir"
        mkdir -p "$stow_dir" || {
            echo "Error: Failed to create directory $stow_dir."
            exit 1
        }
    fi
}

# Function to select the target directory
select_target_dir() {
    print_border "Please select the target directory where symlinks to your packages will be created."
    echo "Note: These symlinks will be hidden using 'eza'."
    echo "1) Use the default application support directory: ~/Library/Application Support"
    echo "2) Organize in your home directory: ~"
    echo "3) Specify a custom directory"
    echo

    read -r -p "Enter the number of your choice: " target_choice

    if [[ "$target_choice" == "1" ]]; then
        target_dir="$HOME/Library/Application Support"
    elif [[ "$target_choice" == "2" ]]; then
        target_dir="$HOME"
    elif [[ "$target_choice" == "3" ]]; then
        read -r -p "Please enter the custom target directory: " target_dir
    else
        echo "Invalid choice. Please enter 1, 2, or 3."
        exit 1
    fi

    # Expand tilde to home directory
    target_dir=$(eval echo "$target_dir")
    echo
    echo "Selected target directory: $target_dir"
    echo

    if [[ ! -d "$target_dir" ]]; then
        echo "Creating directory: $target_dir"
        mkdir -p "$target_dir" || {
            echo "Error: Failed to create directory $target_dir."
            exit 1
        }
    fi
}

# Function to get files to stow
get_files_to_stow() {
    print_border "Please enter the paths of the files you want to manage with Stow, separated by spaces (use quotes if necessary):"
    read -r -p "Files to stow: " files_to_stow
    if [[ -z "$files_to_stow" ]]; then
        echo "Error: No files specified."
        exit 1
    fi
}

# Function to get the package name
get_package_name() {
    print_border "Please enter a name for this package (e.g., bash, zsh, nvim):"
    read -r -p "Package name: " package_name
    if [[ -z "$package_name" ]]; then
        echo "Error: No package name specified."
        exit 1
    fi
}

# Function to create package directory and move files
move_files_to_package() {
    local package_dir
    package_dir=$(eval echo "$stow_dir/$package_name")
    mkdir -p "$package_dir"

    # Split the files_to_stow string into an array
    IFS=' ' read -r -a files_array <<<"$files_to_stow"

    for file in "${files_array[@]}"; do
        # Expand tilde to home directory
        file=$(eval echo "$file")

        if [[ -e "$file" ]]; then
            mv "$file" "$package_dir/"
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to move $file to $package_dir."
                exit 1
            else
                echo "Moved file: $file --> $package_dir/$(basename "$file")"
            fi
        else
            echo "Warning: $file does not exist."
        fi
    done
}

# Function to run the stow command
run_stow_command() {
    # Expand tilde to home directory for stow_dir and target_dir
    stow_dir=$(eval echo "$stow_dir")
    target_dir=$(eval echo "$target_dir")

    # Check and create the target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir" || {
            echo "Error: Failed to create target directory $target_dir."
            exit 1
        }
    fi

    stow --dir="$stow_dir" --target="$target_dir" -S "$package_name" || {
        echo "Error occurred while running stow for package: $package_name"
        exit 1
    }
}

# Main script execution
display_banner
select_operation_mode

# Collect stow results
stow_results=()

# Process configuration file or manual input
if [[ "$mode_choice" == "1" ]]; then
    read_config_file "./stower_config"
else
    select_stow_dir
    select_target_dir
    get_files_to_stow
    get_package_name
    move_files_to_package
    run_stow_command
fi

# Output stow results
echo
print_border "Stow Results"
for result in "${stow_results[@]}"; do
    echo -e "$result"
    echo
done
