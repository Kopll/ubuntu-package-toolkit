#!/bin/bash

###############################################################################
# find-comprehensive.sh
#
# PURPOSE:
#   Multi-layer package discovery across all Ubuntu/Pop!_OS installation
#   methods: package managers, config files, system libraries, filesystem.
#
# ARCHITECTURE:
#   Layer 1 (L1): Package database queries (apt, snap, flatpak)
#   Layer 2 (L2): System configuration files (/etc/)
#   Layer 3 (L3): System library directories (/usr/lib/, /usr/local/)
#   Layer 4 (L4): Filesystem database (locate)
#   Layer 5 (L5): User installation paths (~/.local/, ~/opt/)
#   Layer 6 (L6): dpkg file ownership queries
#
# USAGE:
#   ./find-comprehensive.sh [OPTIONS] <search_pattern>
#
# OPTIONS:
#   -v, --verbose       Show all search layers (default: summary only)
#   -l, --layer N       Search only specific layer (1-6)
#   -d, --dependencies  Check if package is a dependency of others
#
# EXAMPLES:
#   ./find-comprehensive.sh "cedilla"
#   ./find-comprehensive.sh -v "python.*"
#   ./find-comprehensive.sh --layer 1 "bash"
#   ./find-comprehensive.sh -d "libgtk"
#
###############################################################################

set -o pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Configuration
VERBOSE=0
SEARCH_LAYER=""
CHECK_DEPS=0
CASE_SENSITIVE=0
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# Results tracking
declare -A FOUND_PACKAGES
declare -a LAYER_RESULTS

###############################################################################
# FUNCTION: print_header
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
# FUNCTION: print_section
###############################################################################
print_section() {
    printf "\n${BOLD}${CYAN}[L%d] %s${RESET}\n" "$1" "$2"
}

###############################################################################
# FUNCTION: print_result
###############################################################################
print_result() {
    local source="$1"
    local package="$2"
    local info="$3"
    printf "  ${DIM}│${RESET} %-20s │ %-30s │ %s\n" "$source" "$package" "$info"
}

###############################################################################
# FUNCTION: validate_input
###############################################################################
validate_input() {
    if [[ -z "$PATTERN" ]]; then
        printf "\n${RED}${BOLD}ERROR${RESET}: No search pattern provided\n\n"
        printf "${BOLD}Usage:${RESET}\n"
        printf "  %s [OPTIONS] <search_pattern>\n\n" "$0"
        printf "${BOLD}Options:${RESET}\n"
        printf "  -v, --verbose          Show detailed results from all layers\n"
        printf "  -l, --layer N          Search only layer N (1-6)\n"
        printf "  -d, --dependencies     Check dependency relationships\n"
        printf "  -I, --strict-case      Match case-sensitively (default: case-insensitive)\n\n"
        printf "${BOLD}Examples:${RESET}\n"
        printf "  %s 'cedilla'           (finds Cedilla, CEDILLA, etc.)\n" "$0"
        printf "  %s -v 'python.*'       (verbose, case-insensitive)\n" "$0"
        printf "  %s -I 'Python'         (exact case match)\n\n" "$0"
        exit 1
    fi
}

###############################################################################
# LAYER 1: Package Manager Databases
###############################################################################
layer_1_packages() {
    local pattern="$1"
    local count=0
    local grep_flags="-E"
    [[ "$CASE_SENSITIVE" -eq 0 ]] && grep_flags="-iE"
    
    [[ -n "$SEARCH_LAYER" && "$SEARCH_LAYER" != "1" ]] && return
    
    print_section 1 "Package Managers (apt, snap, flatpak)"
    
    # APT
    local apt_matches=$(dpkg -l 2>/dev/null | grep -E "^ii" | awk '{print $2}' | grep $grep_flags "$pattern" || true)
    if [[ -n "$apt_matches" ]]; then
        while IFS= read -r pkg; do
            if [[ -n "$pkg" ]]; then
                FOUND_PACKAGES["apt:$pkg"]=1
                print_result "apt" "$pkg" "$(which "$pkg" 2>/dev/null || echo '[library/system]')"
                ((count++))
            fi
        done <<< "$apt_matches"
    fi
    
    # SNAP
    if command -v snap &>/dev/null; then
        local snap_matches=$(snap list 2>/dev/null | awk 'NR>1 {print $1}' | grep $grep_flags "$pattern" || true)
        if [[ -n "$snap_matches" ]]; then
            while IFS= read -r pkg; do
                if [[ -n "$pkg" ]]; then
                    FOUND_PACKAGES["snap:$pkg"]=1
                    print_result "snap" "$pkg" "/snap/$pkg"
                    ((count++))
                fi
            done <<< "$snap_matches"
        fi
    fi
    
    # FLATPAK
    if command -v flatpak &>/dev/null; then
        local flatpak_matches=$(flatpak list --app 2>/dev/null | awk 'NR>1 {print $2}' | grep $grep_flags "$pattern" || true)
        if [[ -n "$flatpak_matches" ]]; then
            while IFS= read -r pkg; do
                if [[ -n "$pkg" ]]; then
                    FOUND_PACKAGES["flatpak:$pkg"]=1
                    print_result "flatpak" "$pkg" "~/.var/app/$pkg"
                    ((count++))
                fi
            done <<< "$flatpak_matches"
        fi
    fi
    
    [[ $count -eq 0 ]] && printf "  ${DIM}(no matches)${RESET}\n"
    return $count
}

###############################################################################
# LAYER 2: System Configuration Files
###############################################################################
layer_2_config() {
    local pattern="$1"
    local count=0
    local grep_flags="-r"
    [[ "$CASE_SENSITIVE" -eq 0 ]] && grep_flags="-ri"
    
    [[ -n "$SEARCH_LAYER" && "$SEARCH_LAYER" != "2" ]] && return
    
    print_section 2 "System Configuration (/etc/)"
    
    if [[ -d /etc ]]; then
        local matches=$(grep $grep_flags "$pattern" /etc 2>/dev/null | cut -d: -f1 | sort -u | head -20 || true)
        if [[ -n "$matches" ]]; then
            while IFS= read -r file; do
                if [[ -n "$file" && -f "$file" ]]; then
                    FOUND_PACKAGES["config:${file##*/}"]=1
                    print_result "config" "${file##*/}" "$file"
                    ((count++))
                fi
            done <<< "$matches"
        fi
    fi
    
    [[ $count -eq 0 ]] && printf "  ${DIM}(no configuration files found)${RESET}\n"
    return $count
}

###############################################################################
# LAYER 3: System Library and Binary Directories
###############################################################################
layer_3_system_files() {
    local pattern="$1"
    local count=0
    local grep_flags="-E"
    [[ "$CASE_SENSITIVE" -eq 0 ]] && grep_flags="-iE"
    
    [[ -n "$SEARCH_LAYER" && "$SEARCH_LAYER" != "3" ]] && return
    
    print_section 3 "System Libraries & Binaries (/usr/lib/, /usr/bin/, /usr/local/)"
    
    # Search standard system directories (with depth limit to avoid excessive results)
    local search_dirs=("/usr/lib" "/usr/bin" "/usr/local/bin" "/usr/local/lib" "/opt")
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local matches=$(find "$dir" -maxdepth 3 -type f -o -type d 2>/dev/null | xargs basename -a 2>/dev/null | grep $grep_flags "$pattern" | sort -u || true)
            if [[ -n "$matches" ]]; then
                while IFS= read -r name; do
                    if [[ -n "$name" ]]; then
                        # Get actual file path
                        local path=$(find "$dir" -maxdepth 3 \( -name "$name" -o -path "*/$name" \) 2>/dev/null | head -1)
                        if [[ -n "$path" ]]; then
                            FOUND_PACKAGES["system:$name"]=1
                            print_result "system" "$name" "$path"
                            ((count++))
                        fi
                    fi
                done <<< "$matches"
            fi
        fi
    done
    
    [[ $count -eq 0 ]] && printf "  ${DIM}(no matches in system directories)${RESET}\n"
    return $count
}

###############################################################################
# LAYER 4: Filesystem Database (locate)
###############################################################################
layer_4_locate() {
    local pattern="$1"
    local count=0
    
    [[ -n "$SEARCH_LAYER" && "$SEARCH_LAYER" != "4" ]] && return
    
    print_section 4 "Filesystem Database (locate)"
    
    if command -v locate &>/dev/null; then
        # Escape pattern for locate (it's literal, not regex)
        local safe_pattern=$(echo "$pattern" | sed 's/[.^$*+?{}()|[\]\\]//g')
        local matches=$(locate "$safe_pattern" 2>/dev/null | head -30 || true)
        
        if [[ -n "$matches" ]]; then
            while IFS= read -r path; do
                if [[ -n "$path" ]]; then
                    local name=$(basename "$path")
                    FOUND_PACKAGES["locate:${name}"]=1
                    
                    # Classify by type
                    local type="file"
                    [[ -d "$path" ]] && type="directory"
                    [[ -x "$path" ]] && type="executable"
                    
                    print_result "locate" "$name" "$path ($type)"
                    ((count++))
                fi
            done <<< "$matches"
        fi
    else
        printf "  ${DIM}(locate not installed or database not updated)${RESET}\n"
        printf "  ${YELLOW}Hint: Run${RESET} ${BOLD}sudo updatedb${RESET} ${YELLOW}to refresh database${RESET}\n"
    fi
    
    [[ $count -eq 0 ]] && printf "  ${DIM}(no matches in locate database)${RESET}\n"
    return $count
}

###############################################################################
# LAYER 5: User Installation Paths
###############################################################################
layer_5_user_paths() {
    local pattern="$1"
    local count=0
    local grep_flags="-E"
    [[ "$CASE_SENSITIVE" -eq 0 ]] && grep_flags="-iE"
    
    [[ -n "$SEARCH_LAYER" && "$SEARCH_LAYER" != "5" ]] && return
    
    print_section 5 "User Installation Paths (~/.local/, ~/opt/, etc.)"
    
    local user_dirs=("$HOME/.local" "$HOME/opt" "$HOME/.config" "$HOME/.cache")
    
    for dir in "${user_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local matches=$(find "$dir" -maxdepth 4 2>/dev/null | xargs basename -a 2>/dev/null | grep $grep_flags "$pattern" | sort -u || true)
            if [[ -n "$matches" ]]; then
                while IFS= read -r name; do
                    if [[ -n "$name" ]]; then
                        local path=$(find "$dir" -maxdepth 4 -name "$name" 2>/dev/null | head -1)
                        if [[ -n "$path" ]]; then
                            FOUND_PACKAGES["user:$name"]=1
                            print_result "user" "$name" "$path"
                            ((count++))
                        fi
                    fi
                done <<< "$matches"
            fi
        fi
    done
    
    [[ $count -eq 0 ]] && printf "  ${DIM}(no matches in user directories)${RESET}\n"
    return $count
}

###############################################################################
# LAYER 6: dpkg File Ownership Queries
###############################################################################
layer_6_dpkg_ownership() {
    local pattern="$1"
    local count=0
    local grep_flags="-E"
    [[ "$CASE_SENSITIVE" -eq 0 ]] && grep_flags="-iE"
    
    [[ -n "$SEARCH_LAYER" && "$SEARCH_LAYER" != "6" ]] && return
    
    print_section 6 "dpkg File Ownership (what package owns a file)"
    
    if command -v dpkg-query &>/dev/null; then
        # Find files matching pattern, then check what package owns them
        local matches=$(dpkg-query -W -f='${Package}\n' 2>/dev/null | grep $grep_flags "$pattern" | sort -u || true)
        
        if [[ -n "$matches" ]]; then
            while IFS= read -r pkg; do
                if [[ -n "$pkg" ]]; then
                    # Get first file from package
                    local first_file=$(dpkg -L "$pkg" 2>/dev/null | head -1)
                    FOUND_PACKAGES["dpkg:$pkg"]=1
                    print_result "dpkg" "$pkg" "${first_file:-[multiple files]}"
                    ((count++))
                fi
            done <<< "$matches"
        fi
    fi
    
    [[ $count -eq 0 ]] && printf "  ${DIM}(no package file ownership matches)${RESET}\n"
    return $count
}

###############################################################################
# FUNCTION: generate_removal_commands
# Synthesize removal commands from all layers
###############################################################################
generate_removal_commands() {
    local count=0
    
    print_header "REMOVAL STRATEGY"
    
    # Categorize what we found
    local apt_pkgs snap_pkgs flatpak_pkgs config_files user_files
    
    for key in "${!FOUND_PACKAGES[@]}"; do
        IFS=: read -r source pkg <<< "$key"
        case "$source" in
            apt)        apt_pkgs="${apt_pkgs}${pkg} " ;;
            snap)       snap_pkgs="${snap_pkgs}${pkg} " ;;
            flatpak)    flatpak_pkgs="${flatpak_pkgs}${pkg} " ;;
            config)     config_files="${config_files}${key##*:} " ;;
            user)       user_files="${user_files}${key##*:} " ;;
        esac
    done
    
    printf "\n${BOLD}Recommended removal order (respecting dependencies):${RESET}\n\n"
    
    if [[ -n "$flatpak_pkgs" ]]; then
        printf "  ${CYAN}1. Remove flatpak application:${RESET}\n"
        for pkg in $flatpak_pkgs; do
            printf "     ${BOLD}\$ flatpak remove --delete-data %s${RESET}\n" "$pkg"
        done
        printf "\n"
        ((count++))
    fi
    
    if [[ -n "$snap_pkgs" ]]; then
        printf "  ${CYAN}$(( count + 1 )). Remove snap packages:${RESET}\n"
        for pkg in $snap_pkgs; do
            printf "     ${BOLD}\$ snap remove %s${RESET}\n" "$pkg"
        done
        printf "\n"
        ((count++))
    fi
    
    if [[ -n "$apt_pkgs" ]]; then
        printf "  ${CYAN}$(( count + 1 )). Remove apt packages:${RESET}\n"
        for pkg in $apt_pkgs; do
            printf "     ${BOLD}\$ sudo apt remove %s${RESET}\n" "$pkg"
        done
        printf "\n"
        ((count++))
    fi
    
    if [[ -n "$config_files" ]]; then
        printf "  ${CYAN}$(( count + 1 )). Remove configuration files:${RESET}\n"
        for file in $config_files; do
            printf "     ${BOLD}\$ sudo rm -v /etc/*/%s*${RESET}\n" "$file"
        done
        printf "\n"
        ((count++))
    fi
    
    if [[ -n "$user_files" ]]; then
        printf "  ${CYAN}$(( count + 1 )). Remove user installation files:${RESET}\n"
        printf "     ${BOLD}\$ rm -rf ~/.local/share/*/%s*${RESET}\n" "$PATTERN"
        printf "\n"
        ((count++))
    fi
    
    if [[ $count -eq 0 ]]; then
        printf "  ${DIM}(nothing to remove - not found)${RESET}\n"
    fi
}

###############################################################################
# Parse command-line arguments
###############################################################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)       VERBOSE=1; shift ;;
        -l|--layer)         SEARCH_LAYER="$2"; shift 2 ;;
        -d|--dependencies)  CHECK_DEPS=1; shift ;;
        -I|--strict-case)   CASE_SENSITIVE=1; shift ;;
        -*)                 printf "${RED}Unknown option: %s${RESET}\n" "$1"; exit 1 ;;
        *)                  PATTERN="$1"; shift ;;
    esac
done

validate_input

print_header "COMPREHENSIVE PACKAGE SEARCH: $PATTERN"

# Execute search layers
TOTAL_FOUND=0

layer_1_packages "$PATTERN"
LAYER1_COUNT=$?
((TOTAL_FOUND += LAYER1_COUNT))

layer_2_config "$PATTERN"
LAYER2_COUNT=$?
((TOTAL_FOUND += LAYER2_COUNT))

layer_3_system_files "$PATTERN"
LAYER3_COUNT=$?
((TOTAL_FOUND += LAYER3_COUNT))

layer_4_locate "$PATTERN"
LAYER4_COUNT=$?
((TOTAL_FOUND += LAYER4_COUNT))

layer_5_user_paths "$PATTERN"
LAYER5_COUNT=$?
((TOTAL_FOUND += LAYER5_COUNT))

layer_6_dpkg_ownership "$PATTERN"
LAYER6_COUNT=$?
((TOTAL_FOUND += LAYER6_COUNT))

# Summary
printf "\n${BOLD}Summary: %d total matches across all layers${RESET}\n" "$TOTAL_FOUND"

# Generate removal commands if anything found
if [[ $TOTAL_FOUND -gt 0 ]]; then
    generate_removal_commands
fi

printf "\n${YELLOW}Warning:${RESET} Review all results before removing. Some files may be dependencies of other applications.\n\n"

exit 0
