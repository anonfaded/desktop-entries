#!/bin/bash

# Directories
SNAP_DESKTOP_DIR="/var/lib/snapd/desktop/applications"
USER_DESKTOP_DIR="$HOME/.local/share/applications"

# Function to display colored messages
print_message() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}"
}

# Function to clear the terminal screen
clear_terminal() {
    clear
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if directories exist
if [ ! -d "$SNAP_DESKTOP_DIR" ]; then
    print_message "Error: $SNAP_DESKTOP_DIR does not exist or is not accessible." "$RED"
    exit 1
fi

if [ ! -d "$USER_DESKTOP_DIR" ]; then
    print_message "Error: $USER_DESKTOP_DIR does not exist or is not accessible." "$RED"
    exit 1
fi

# Count number of desktop files
num_files=$(find "$SNAP_DESKTOP_DIR" -type f -name "*.desktop" | wc -l)
desktop_files=( "$SNAP_DESKTOP_DIR"/*.desktop )

# Print summary and prompt user to choose action
clear_terminal
print_message "Move Snap Store Desktop Entries" "$CYAN"
echo "--------------------------------------------------"
print_message "Visit https://github.com/anonfaded/desktop-entries" "$RED"
echo "--------------------------------------------------"
print_message "Found $num_files desktop entries to move:" "$CYAN"
echo ""

# List all desktop files
for (( i=0; i<${#desktop_files[@]}; i++ )); do
    echo "$(basename ${desktop_files[$i]})"
done

echo ""
print_message "Select an action:" "$CYAN"
echo "1. Move and replace all existing files at destination directory"
echo "2. Skip all existing files and move the rest"
echo "3. Prompt for each file (if found duplicated)"
echo ""

# Prompt user for action choice
read -p "Enter your choice (1/2/3): " action_choice

# Validate user input
if [[ "$action_choice" != "1" && "$action_choice" != "2" && "$action_choice" != "3" ]]; then
    print_message "Invalid choice. Exiting." "$RED"
    exit 1
fi

# Array to store desktop files moved
MOVED_FILES=()

# Move each desktop file from Snap directory to the user's application directory
for desktop_file in "${desktop_files[@]}"; do
    base_name=$(basename "$desktop_file")
    dest_file="$USER_DESKTOP_DIR/$base_name"
    
    if [ -f "$dest_file" ]; then
        case $action_choice in
            1)
                sudo mv -f "$desktop_file" "$dest_file"
                print_message "Replaced: $base_name" "$GREEN"
                MOVED_FILES+=("$base_name (replaced)")
                ;;
            2)
                print_message "Skipped: $base_name" "$CYAN"
                MOVED_FILES+=("$base_name (skipped)")
                ;;
            3)
                print_message "A desktop file with the same name already exists: $base_name" "$YELLOW"
                read -p "Do you want to replace it? (y/n): " replace_choice
                
                if [ "$replace_choice" == "y" ]; then
                    sudo mv -f "$desktop_file" "$dest_file"
                    print_message "Replaced: $base_name" "$GREEN"
                    MOVED_FILES+=("$base_name (replaced)")
                else
                    print_message "Skipped: $base_name" "$CYAN"
                    MOVED_FILES+=("$base_name (skipped)")
                fi
                ;;
        esac
    else
        sudo mv "$desktop_file" "$dest_file"
        print_message "Moved: $base_name" "$GREEN"
        MOVED_FILES+=("$base_name")
    fi
done

# Check if any files were moved
if [ ${#MOVED_FILES[@]} -eq 0 ]; then
    print_message "No new desktop files found to move. Exiting safely." "$YELLOW"
    exit 0
fi

# Display summary
echo -e "\n${CYAN}Summary:${NC}"
echo "---------"
for entry in "${MOVED_FILES[@]}"; do
    echo "$entry"
done

echo -e "\nSnap Store desktop entries moved to $USER_DESKTOP_DIR."

