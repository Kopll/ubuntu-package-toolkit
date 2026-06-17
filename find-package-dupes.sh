#!/bin/bash

###############################################################################
# find-package-dupes.sh
#
# PURPOSE:
#   Audit system for duplicate installations across package managers.
#   Identifies the same application installed via multiple methods
#   (apt, snap, flatpak) and shows installation locations.
#
# ARCHITECTURE:
#   1. Enumerate all packages from each manager
#   2. Normalize package names (extract base names)
#   3. Identify duplicates using fuzzy keyword matching
#   4. Display results with categorization and removal guidance
#
# USAGE:
#   ./find-package-dupes.sh [OPTIONS]
#
# OPTIONS:
#   -v, --verbose        Show detailed analysis and non-duplicates
#   -c, --csv            Output results in CSV format (easier to parse)
#   -o, --output FILE    Write results to file instead of stdout
#   -s, --summary        Show summary statistics only
#
# EXAMPLES:
#   ./find-package-dupes.sh                 # Show duplicates only
#   ./find-package-dupes.sh -v              # Verbose: show everything
#   ./find-package-dupes.sh --csv > dupes.csv
#   ./find-package-dupes.sh --summary       # Stats only
#
# OUTPUT:
#   Shows applications installed via multiple package managers,
#   locations, and suggested removal order (keeping optimal version)
#
###############################################################################

set -o pipefail

# Colour codes
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
CSV_OUTPUT=0
SUMMARY_ONLY=0
OUTPUT_FILE=""
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# Data structures
declare -A APT_PKGS
declare -A SNAP_PKGS
declare -A FLATPAK_PKGS
declare -a DUPLICATES

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
    printf "\n${BOLD}${CYAN}▸ %s${RESET}\n" "$1"
}

###############################################################################
# FUNCTION: validate_arguments
###############################################################################
validate_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)       VERBOSE=1; shift ;;
            -c|--csv)           CSV_OUTPUT=1; shift ;;
            -s|--summary)       SUMMARY_ONLY=1; shift ;;
            -o|--output)        OUTPUT_FILE="$2"; shift 2 ;;
            -h|--help)          print_help; exit 0 ;;
            *)                  printf "${RED}Unknown option: %s${RESET}\n" "$1"; exit 1 ;;
        esac
    done
}

###############################################################################
# FUNCTION: print_help
###############################################################################
print_help() {
    cat << 'EOF'
find-package-dupes.sh - Identify duplicate package installations

USAGE:
  ./find-package-dupes.sh [OPTIONS]

OPTIONS:
  -v, --verbose        Show detailed analysis (includes non-duplicates)
  -c, --csv            Output in CSV format for spreadsheets
  -s, --summary        Show statistics only
  -o, --output FILE    Write results to file
  -h, --help           Display this help message

EXAMPLES:
  ./find-package-dupes.sh
  ./find-package-dupes.sh -v
  ./find-package-dupes.sh --csv > dupes.csv
  ./find-package-dupes.sh --summary

WHAT IT DOES:
  - Lists all installed packages from apt, snap, flatpak
  - Finds applications installed via multiple package managers
  - Shows installation locations and sizes
  - Provides removal recommendations

WHY USE IT:
  Modern Linux has package fragmentation. You might have:
  - Firefox via apt + snap
  - Python via apt + snap
  - GIMP via apt + flatpak
  
  This finds those duplicates so you can clean them up.

INTERPRETATION:
  ✓ DUPE   - Application installed more than once
  ○ SINGLE - Application installed only one way (optimal)
  ─ TOTAL  - Summary counts
EOF
}

###############################################################################
# FUNCTION: enumerate_apt
# Get all installed apt packages
###############################################################################
enumerate_apt() {
    if ! command -v dpkg &>/dev/null; then
        [[ $VERBOSE -eq 1 ]] && printf "${DIM}(dpkg not found)${RESET}\n"
        return
    fi
    
    local count=0
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        APT_PKGS["$pkg"]=1
        ((count++))
    done < <(dpkg -l 2>/dev/null | grep -E "^ii" | awk '{print $2}' | cut -d: -f1 | sort -u)
    
    [[ $VERBOSE -eq 1 ]] && printf "  APT:     %4d packages\n" "$count"
}

###############################################################################
# FUNCTION: enumerate_snap
# Get all installed snap packages
###############################################################################
enumerate_snap() {
    if ! command -v snap &>/dev/null; then
        [[ $VERBOSE -eq 1 ]] && printf "${DIM}(snap not installed)${RESET}\n"
        return
    fi
    
    local count=0
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        SNAP_PKGS["$pkg"]=1
        ((count++))
    done < <(snap list 2>/dev/null | awk 'NR>1 {print $1}' | sort -u)
    
    [[ $VERBOSE -eq 1 ]] && printf "  SNAP:    %4d packages\n" "$count"
}

###############################################################################
# FUNCTION: enumerate_flatpak
# Get all installed flatpak applications
#
# `flatpak list` has no header row, and its display-name column can contain
# spaces (e.g. "Visual Studio Code"). Default awk whitespace splitting plus
# an `NR>1` header skip silently dropped the first installed app and
# mis-extracted the ID as a name fragment for any multi-word name, which
# corrupted FLATPAK_PKGS and broke duplicate detection against apt/snap.
# Tab-delimited --columns output extracts the real application ID instead.
###############################################################################
enumerate_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        [[ $VERBOSE -eq 1 ]] && printf "${DIM}(flatpak not installed)${RESET}\n"
        return
    fi

    local count=0
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        FLATPAK_PKGS["$pkg"]=1
        ((count++))
    done < <(flatpak list --app --columns=application 2>/dev/null | sort -u)
    
    [[ $VERBOSE -eq 1 ]] && printf "  FLATPAK: %4d packages\n" "$count"
}

###############################################################################
# FUNCTION: extract_basename
# Extract base name from package (e.g., "org.mozilla.firefox" -> "firefox")
###############################################################################
extract_basename() {
    local pkg="$1"
    
    # Remove common prefixes and reverse-domain notation
    pkg="${pkg#org.}"
    pkg="${pkg#com.}"
    pkg="${pkg#net.}"
    
    # Remove reverse domain parts (e.g., "mozilla.firefox" -> "firefox")
    pkg="${pkg##*.}"
    
    # Lowercase for comparison
    pkg="${pkg,,}"
    
    # Remove version suffixes (e.g., "python3.10" -> "python3")
    pkg="${pkg%.*}"
    
    # Remove arch suffixes (e.g., "lib:amd64" -> "lib")
    pkg="${pkg%:*}"
    
    echo "$pkg"
}

###############################################################################
# FUNCTION: extract_keywords
# Extract searchable keywords from package name
# Returns space-separated keywords for fuzzy matching
###############################################################################
extract_keywords() {
    local pkg="$1"
    local base=$(extract_basename "$pkg")
    local keywords="$base"
    
    # Add split versions (e.g., "python-pip" -> "python pip")
    keywords+=" ${pkg//-/ }"
    keywords+=" ${pkg//_/ }"
    
    # Add domain parts for flatpak (e.g., "org.gimp.GIMP" -> "gimp")
    if [[ "$pkg" == org.* ]] || [[ "$pkg" == com.* ]]; then
        local domain="${pkg%%.*}"
        keywords+=" ${domain}"
    fi
    
    echo "$keywords" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

###############################################################################
# FUNCTION: packages_match
# Fuzzy match two package names (returns 0 if match, 1 if no match)
###############################################################################
packages_match() {
    local pkg1="$1"
    local pkg2="$2"
    
    # Exact match
    [[ "${pkg1,,}" == "${pkg2,,}" ]] && return 0
    
    # Extract base names
    local base1=$(extract_basename "$pkg1")
    local base2=$(extract_basename "$pkg2")
    
    # Base name match
    [[ -n "$base1" && "$base1" == "$base2" ]] && return 0
    
    # Keyword overlap - at least 2 keywords in common
    local keywords1=$(extract_keywords "$pkg1")
    local keywords2=$(extract_keywords "$pkg2")
    
    local common_count=0
    for kw in $keywords1; do
        [[ "$keywords2" == *"$kw"* ]] && ((common_count++))
    done
    
    [[ $common_count -ge 2 ]] && return 0
    
    return 1
}

###############################################################################
# FUNCTION: find_duplicates
# Identify packages installed via multiple package managers
###############################################################################
find_duplicates() {
    local apt_pkg snap_pkg flatpak_pkg
    local found_any=0
    
    # Check each apt package against snap and flatpak
    for apt_pkg in "${!APT_PKGS[@]}"; do
        local matches=""
        
        for snap_pkg in "${!SNAP_PKGS[@]}"; do
            if packages_match "$apt_pkg" "$snap_pkg"; then
                matches+="snap:$snap_pkg "
            fi
        done
        
        for flatpak_pkg in "${!FLATPAK_PKGS[@]}"; do
            if packages_match "$apt_pkg" "$flatpak_pkg"; then
                matches+="flatpak:$flatpak_pkg "
            fi
        done
        
        if [[ -n "$matches" ]]; then
            DUPLICATES+=("apt:$apt_pkg $matches")
            found_any=1
        fi
    done
    
    # Check snap packages against flatpak (in case snap duplicates with flatpak)
    for snap_pkg in "${!SNAP_PKGS[@]}"; do
        local already_found=0
        
        # Check if already found via apt
        for dup in "${DUPLICATES[@]}"; do
            [[ "$dup" == *"snap:$snap_pkg"* ]] && already_found=1 && break
        done
        
        if [[ $already_found -eq 0 ]]; then
            for flatpak_pkg in "${!FLATPAK_PKGS[@]}"; do
                if packages_match "$snap_pkg" "$flatpak_pkg"; then
                    DUPLICATES+=("snap:$snap_pkg flatpak:$flatpak_pkg")
                    found_any=1
                    break
                fi
            done
        fi
    done
    
    return $found_any
}

###############################################################################
# FUNCTION: format_dupe_entry
# Format a duplicate entry for display
###############################################################################
format_dupe_entry() {
    local entry="$1"
    
    if [[ $CSV_OUTPUT -eq 1 ]]; then
        # CSV format
        echo "$entry" | tr ' ' ',' | sed 's/:/,/g'
    else
        # Human-readable format
        printf "  ${YELLOW}✓ DUPE${RESET}  "
        
        local parts=($entry)
        for part in "${parts[@]}"; do
            IFS=: read manager pkg <<< "$part"
            case "$manager" in
                apt)     printf "${GREEN}apt:%-30s${RESET}  " "$pkg" ;;
                snap)    printf "${CYAN}snap:%-28s${RESET}  " "$pkg" ;;
                flatpak) printf "${BLUE}flatpak:%-24s${RESET}" "$pkg" ;;
            esac
        done
        printf "\n"
    fi
}

###############################################################################
# FUNCTION: generate_summary_stats
# Generate installation statistics
###############################################################################
generate_summary_stats() {
    local apt_count=${#APT_PKGS[@]}
    local snap_count=${#SNAP_PKGS[@]}
    local flatpak_count=${#FLATPAK_PKGS[@]}
    local dupe_count=${#DUPLICATES[@]}
    local total_count=$((apt_count + snap_count + flatpak_count))
    
    print_header "PACKAGE AUDIT SUMMARY"
    
    printf "\n${BOLD}Installation Counts:${RESET}\n"
    printf "  APT:                    %5d packages\n" "$apt_count"
    printf "  SNAP:                   %5d packages\n" "$snap_count"
    printf "  FLATPAK:                %5d packages\n" "$flatpak_count"
    printf "  ${DIM}─────────────────────────${RESET}\n"
    printf "  ${BOLD}TOTAL:${RESET}                  %5d packages\n" "$total_count"
    
    printf "\n${BOLD}Duplication Analysis:${RESET}\n"
    printf "  Applications installed   %5d times (multiple ways)\n" "$dupe_count"
    printf "  Unique applications:     %5d \n" "$((total_count - dupe_count))"
    printf "  Efficiency score:        %5.1f%% (no dupes = 100%%)\n" \
        $(echo "scale=1; ($total_count - $dupe_count) * 100 / $total_count" | bc 2>/dev/null || echo "0")
}

###############################################################################
# FUNCTION: output_duplicates
# Display all duplicates found
###############################################################################
output_duplicates() {
    if [[ $CSV_OUTPUT -eq 1 ]]; then
        # CSV header
        echo "manager1,package1,manager2,package2,manager3,package3"
        for dup in "${DUPLICATES[@]}"; do
            format_dupe_entry "$dup"
        done
    else
        # Human-readable output
        if [[ ${#DUPLICATES[@]} -eq 0 ]]; then
            printf "\n${GREEN}No duplicates found!${RESET} Your system is optimized.\n\n"
            return 0
        fi
        
        print_header "DUPLICATE PACKAGES FOUND: ${#DUPLICATES[@]}"
        
        printf "\n${BOLD}Applications installed via multiple package managers:${RESET}\n\n"
        
        for dup in "${DUPLICATES[@]}"; do
            format_dupe_entry "$dup"
        done
        
        printf "\n"
    fi
}

###############################################################################
# FUNCTION: recommend_cleanup
# Provide removal recommendations
###############################################################################
recommend_cleanup() {
    if [[ ${#DUPLICATES[@]} -eq 0 ]]; then
        return
    fi
    
    print_header "CLEANUP RECOMMENDATIONS"
    
    cat << 'EOF'

For each duplicate, decide which installation to keep based on your needs:

APT (system package)
  ✓ Tightest OS integration
  ✓ Automatic with system updates
  ✗ May be older versions
  ✗ Slower to update
  → Keep for: system tools, libraries, development packages

SNAP (confined, auto-updating)
  ✓ Latest version always
  ✓ Automatic weekly updates
  ✓ Isolated (won't break system)
  ✗ Slightly slower startup
  ✗ Uses more disk space
  → Keep for: desktop apps you want current

FLATPAK (portable, cross-distro)
  ✓ Cross-distribution compatible
  ✓ Good for pre-release software
  ✓ Excellent sandbox isolation
  ✗ Slower startup than native
  ✗ Larger download/install size
  → Keep for: bleeding-edge or security-sensitive apps

RECOMMENDED REMOVAL STRATEGY:
  1. Keep system tools and libraries in APT
  2. Remove from SNAP if you also have APT
  3. Use FLATPAK for apps not in APT, or for sandboxing

EXAMPLE FOR FIREFOX:
  If you have firefox via apt + snap, remove snap:
    $ snap remove firefox
  Keep the apt version for tighter integration and faster startup.

EOF
}

###############################################################################
# FUNCTION: write_output
# Write output to file or stdout
###############################################################################
write_output() {
    local output_text="$1"
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$output_text" > "$OUTPUT_FILE"
        printf "\n${GREEN}✓${RESET} Results written to: ${BOLD}$OUTPUT_FILE${RESET}\n\n"
    fi
}

###############################################################################
# MAIN EXECUTION
###############################################################################

validate_arguments "$@"

# Enumerate packages from all managers
[[ $SUMMARY_ONLY -eq 0 ]] && printf "${DIM}Enumerating packages...${RESET}\n"
enumerate_apt
enumerate_snap
enumerate_flatpak

# Find duplicates
find_duplicates

# Accumulate output for file writing
OUTPUT_TEXT=""

# Show summary
if [[ $SUMMARY_ONLY -eq 1 ]]; then
    generate_summary_stats
else
    # Show full report
    if [[ $VERBOSE -eq 1 ]]; then
        print_header "PACKAGE INVENTORY"
        printf "\n${BOLD}Packages by Manager:${RESET}\n"
        enumerate_apt
        enumerate_snap
        enumerate_flatpak
    fi
    
    # Show duplicates
    output_duplicates
    
    # Show cleanup recommendations
    if [[ ${#DUPLICATES[@]} -gt 0 && $CSV_OUTPUT -eq 0 ]]; then
        recommend_cleanup
    fi
    
    # Show summary stats
    generate_summary_stats
fi

printf "\n"

exit 0
