#!/bin/bash

###############################################################################
# find-and-manage-package.sh
# 
# PURPOSE:
#   Search for installed applications across multiple package managers
#   (apt, snap, flatpak) on Ubuntu/Pop!_OS systems. Handles cases where
#   an application is installed via multiple methods.
#
# USAGE:
#   ./find-and-manage-package.sh <search_pattern>
#   - search_pattern: regex or literal string to match package names
#
# EXAMPLES:
#   ./find-and-manage-package.sh "siril"
#   ./find-and-manage-package.sh "python.*"
#   ./find-and-manage-package.sh "^gimp$"
#
# OUTPUT:
#   - Installation status and location(s)
#   - Uninstall commands for each found instance
#   - Install commands if not found
#
# REQUIREMENTS:
#   - bash 4+
#   - Common tools: grep, awk, dpkg, snap (optional), flatpak (optional)
#
###############################################################################

set -o pipefail

# Color codes for output readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Terminal width detection
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# Case sensitivity control (default: case-insensitive)
CASE_SENSITIVE=0

###############################################################################
# FUNCTION: print_header
# Print section headers with professional separation
###############################################################################
print_header() {
    local title="$1"
    printf "\n${BOLD}${BLUE}"
    printf '=%.0s' $(seq 1 $TERM_WIDTH)
    printf "\n  %s\n" "$title"
    printf '=%.0s' $(seq 1 $TERM_WIDTH)
    printf "${RESET}\n"
}

###############################################################################
# FUNCTION: print_subheader
# Print sub-section headers
###############################################################################
print_subheader() {
    printf "\n${BOLD}${CYAN}> %s${RESET}\n" "$1"
}

###############################################################################
# FUNCTION: print_found
# Print a found package with color coding
###############################################################################
print_found() {
    printf "${GREEN}[+]${RESET} %s\n" "$1"
}

###############################################################################
# FUNCTION: print_not_found
# Print not found message
###############################################################################
print_not_found() {
    printf "${RED}[-]${RESET} %s\n" "$1"
}

###############################################################################
# FUNCTION: print_package_entry
# Print a single package with formatted columns
###############################################################################
print_package_entry() {
    local manager="$1"
    local package="$2"
    local path="$3"
    printf "  | %-12s | %-30s | %s\n" "$manager" "$package" "$path"
}

###############################################################################
# FUNCTION: search_apt
# Search installed packages in apt/dpkg database
# Returns: list of matching package names
# Note: Case-insensitive by default (use -I flag to make case-sensitive)
###############################################################################
search_apt() {
    local pattern="$1"
    local grep_flags="-E"
    [[ "$CASE_SENSITIVE" -eq 0 ]] && grep_flags="-iE"
    dpkg -l 2>/dev/null | grep -E "^ii" | awk '{print $2}' | grep $grep_flags "$pattern" || true
}

###############################################################################
# FUNCTION: search_snap
# Search installed snap packages
# Returns: list of matching snap package names
# Note: Case-insensitive by default (use -I flag to make case-sensitive)
###############################################################################
search_snap() {
    local pattern="$1"
    local grep_flags="-E"
    [[ "$CASE_SENSITIVE" -eq 0 ]] && grep_flags="-iE"
    if command -v snap &>/dev/null; then
        snap list 2>/dev/null | awk 'NR>1 {print $1}' | grep $grep_flags "$pattern" || true
    fi
}

###############################################################################
# FUNCTION: search_flatpak
# Search installed flatpak packages
# Returns: list of matching flatpak package names
# Note: Case-insensitive by default (use -I flag to make case-sensitive)
###############################################################################
search_flatpak() {
    local pattern="$1"
    local grep_flags="-E"
    [[ "$CASE_SENSITIVE" -eq 0 ]] && grep_flags="-iE"
    if command -v flatpak &>/dev/null; then
        flatpak list --app 2>/dev/null | awk 'NR>1 {print $2}' | grep $grep_flags "$pattern" || true
    fi
}

###############################################################################
# FUNCTION: get_apt_path
# Get the installation path of an apt package
# Returns: binary path if available
###############################################################################
get_apt_path() {
    local package="$1"
    which "$(echo "$package" | cut -d: -f1)" 2>/dev/null || echo "[system package]"
}

###############################################################################
# FUNCTION: get_snap_path
# Get the installation path of a snap package
###############################################################################
get_snap_path() {
    local package="$1"
    echo "/snap/$package"
}

###############################################################################
# FUNCTION: get_flatpak_path
# Get the installation path of a flatpak application
###############################################################################
get_flatpak_path() {
    local package="$1"
    echo "~/.var/app/$package"
}

###############################################################################
# FUNCTION: validate_input
# Ensure search pattern provided and is not empty
###############################################################################
validate_input() {
    if [[ -z "$PATTERN" ]]; then
        printf "\n${RED}${BOLD}ERROR${RESET}: No search pattern provided\n\n"
        printf "${BOLD}Usage:${RESET}\n"
        printf "  %s [OPTIONS] <search_pattern>\n\n" "$0"
        printf "${BOLD}Options:${RESET}\n"
        printf "  -I, --strict-case    Match case-sensitively (default: case-insensitive)\n\n"
        printf "${BOLD}Examples:${RESET}\n"
        printf "  %s 'siril'              (finds siril, Siril, SIRIL, etc.)\n" "$0"
        printf "  %s 'cedilla'            (finds dev.mariinkys.Cedilla)\n" "$0"
        printf "  %s -I 'python'          (exact case match only)\n" "$0"
        printf "  %s 'python.*'           (regex pattern)\n\n" "$0"
        exit 1
    fi
}

###############################################################################
# FUNCTION: generate_install_commands
# Suggest install commands across package managers with professional format
###############################################################################
generate_install_commands() {
    local pattern="$1"
    print_header "INSTALLATION OPTIONS"
    printf "\n${BOLD}Choose one of the following commands:${RESET}\n\n"
    printf "  ${CYAN}APT (system package)${RESET}\n"
    printf "    ${BOLD}\$ sudo apt install %s${RESET}\n\n" "$pattern"
    printf "  ${CYAN}SNAP (confined containerized)${RESET}\n"
    printf "    ${BOLD}\$ snap install %s${RESET}\n\n" "$pattern"
    printf "  ${CYAN}FLATPAK (portable sandbox)${RESET}\n"
    printf "    ${BOLD}\$ flatpak install flathub %s${RESET}\n" "$pattern"
}

###############################################################################
# FUNCTION: generate_uninstall_commands
# Generate uninstall commands for all found instances with professional format
###############################################################################
generate_uninstall_commands() {
    local pattern="$1"
    local apt_results snap_results flatpak_results
    
    apt_results=$(search_apt "$pattern")
    snap_results=$(search_snap "$pattern")
    flatpak_results=$(search_flatpak "$pattern")
    
    print_header "REMOVAL COMMANDS"
    
    local has_removals=0
    
    if [[ -n "$apt_results" ]]; then
        printf "\n${BOLD}${CYAN}> APT Packages${RESET}\n"
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && printf "    ${BOLD}\$ sudo apt remove %s${RESET}\n" "$pkg"
        done <<< "$apt_results"
        has_removals=1
    fi
    
    if [[ -n "$snap_results" ]]; then
        printf "\n${BOLD}${CYAN}> SNAP Packages${RESET}\n"
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && printf "    ${BOLD}\$ snap remove %s${RESET}\n" "$pkg"
        done <<< "$snap_results"
        has_removals=1
    fi
    
    if [[ -n "$flatpak_results" ]]; then
        printf "\n${BOLD}${CYAN}> FLATPAK Packages${RESET}\n"
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && printf "    ${BOLD}\$ flatpak remove %s${RESET}\n" "$pkg"
        done <<< "$flatpak_results"
        has_removals=1
    fi
    
    if [[ $has_removals -eq 1 ]]; then
        printf "\n"
    fi
}

###############################################################################
# Parse Command-Line Arguments
###############################################################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        -I|--strict-case)
            CASE_SENSITIVE=1
            shift
            ;;
        -*)
            printf "${RED}ERROR: Unknown option: %s${RESET}\n" "$1"
            exit 1
            ;;
        *)
            PATTERN="$1"
            shift
            ;;
    esac
done

###############################################################################
# MAIN EXECUTION
###############################################################################

validate_input

apt_matches=$(search_apt "$PATTERN")
snap_matches=$(search_snap "$PATTERN")
flatpak_matches=$(search_flatpak "$PATTERN")

print_header "PACKAGE SEARCH: $PATTERN"

if [[ -z "$apt_matches" && -z "$snap_matches" && -z "$flatpak_matches" ]]; then
    printf "\n${RED}[!]${RESET} Package not found\n"
    printf "    Searched across: apt, snap, flatpak\n"
    generate_install_commands "$PATTERN"
    printf "\n"
    exit 0
fi

# Print results header
printf "\n${BOLD}Installed Instances:${RESET}\n"
printf "  | Manager      | Package Name                   | Location\n"
printf "  |--------------|--------------------------------|---------------------------------------\n"

# Report APT findings
if [[ -n "$apt_matches" ]]; then
    while IFS= read -r pkg; do
        if [[ -n "$pkg" ]]; then
            path=$(get_apt_path "$pkg")
            print_package_entry "apt" "$pkg" "$path"
        fi
    done <<< "$apt_matches"
fi

# Report SNAP findings
if [[ -n "$snap_matches" ]]; then
    while IFS= read -r pkg; do
        if [[ -n "$pkg" ]]; then
            path=$(get_snap_path "$pkg")
            print_package_entry "snap" "$pkg" "$path"
        fi
    done <<< "$snap_matches"
fi

# Report FLATPAK findings
if [[ -n "$flatpak_matches" ]]; then
    while IFS= read -r pkg; do
        if [[ -n "$pkg" ]]; then
            path=$(get_flatpak_path "$pkg")
            print_package_entry "flatpak" "$pkg" "$path"
        fi
    done <<< "$flatpak_matches"
fi

printf "  |--------------|--------------------------------|---------------------------------------\n"

# Generate uninstall commands since we found matches
generate_uninstall_commands "$PATTERN"

printf "${YELLOW}Note:${RESET} Run each uninstall command separately if multiple versions are found.\n\n"

exit 0
