#!/bin/bash

###############################################################################
# INSTALL.sh - Setup script for Ubuntu Package Management Toolkit
#
# This script extracts and optionally installs the package finder toolkit
#
# Usage:
#   bash INSTALL.sh              # Extract to current directory
#   bash INSTALL.sh --system     # Extract + install to /usr/local/bin
#   bash INSTALL.sh --help       # Show this help
#
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

INSTALL_SYSTEM=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --system)
            INSTALL_SYSTEM=1
            shift
            ;;
        --help|-h)
            cat << 'HELPTEXT'
Ubuntu Package Management Toolkit - Installer

USAGE:
  bash INSTALL.sh [OPTIONS]

OPTIONS:
  --system      Install scripts to /usr/local/bin (requires sudo)
  --help        Show this help message

EXAMPLES:
  bash INSTALL.sh
    → Extracts files to current directory

  bash INSTALL.sh --system
    → Extracts + installs scripts to /usr/local/bin
    → Makes scripts available system-wide

WHAT YOU'LL GET:
  ✓ 3 package finder scripts
  ✓ 5 documentation files
  ✓ Ready to use immediately

AFTER INSTALLATION:
  Option A (Local):
    ./find-and-manage-package.sh firefox

  Option B (System-wide):
    find-and-manage-package.sh firefox
    find-comprehensive.sh firefox -v
    find-package-dupes.sh --summary

START HERE:
  Read: README.md
  Then: TOOLKIT_QUICK_REFERENCE.md

HELPTEXT
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Print header
printf "\n${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "${BLUE}${BOLD}  Ubuntu/Pop!_OS Package Management Toolkit Installer${RESET}\n"
printf "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"

# List what will be installed
printf "${BOLD}Files to install:${RESET}\n"
echo "  Scripts:"
echo "    ✓ find-and-manage-package.sh    (quick lookup)"
echo "    ✓ find-comprehensive.sh          (deep 6-layer search)"
echo "    ✓ find-package-dupes.sh          (find duplicates)"
echo ""
echo "  Documentation:"
echo "    ✓ README.md                      (toolkit overview)"
echo "    ✓ TOOLKIT_QUICK_REFERENCE.md     (5-min guide)"
echo "    ✓ FIND_DUPES_GUIDE.md            (detailed guide)"
echo "    ✓ ARCHITECTURE_ANALYSIS.md       (design docs)"
echo "    ✓ CEDILLA_REMOVAL_GUIDE.md       (real-world example)"
echo "    ✓ QUICK_REFERENCE.md             (original docs)"
echo ""

# Make scripts executable
chmod +x find-and-manage-package.sh find-comprehensive.sh find-package-dupes.sh 2>/dev/null || true

printf "${GREEN}✓${RESET} Scripts made executable\n"

# System installation
if [[ $INSTALL_SYSTEM -eq 1 ]]; then
    printf "\n${YELLOW}Installing to system...${RESET}\n"
    
    if ! command -v sudo &>/dev/null; then
        printf "${RED}ERROR: sudo not found. Cannot install system-wide.${RESET}\n"
        printf "Use local installation instead:\n"
        printf "  bash INSTALL.sh (without --system)\n"
        exit 1
    fi
    
    # Create backup of old versions if they exist
    for script in find-and-manage-package.sh find-comprehensive.sh find-package-dupes.sh; do
        if [[ -f "/usr/local/bin/$script" ]]; then
            printf "  Backing up existing: %s\n" "$script"
            sudo cp "/usr/local/bin/$script" "/usr/local/bin/${script}.bak"
        fi
    done
    
    # Install scripts
    printf "\n${BOLD}Installing scripts to /usr/local/bin...${RESET}\n"
    sudo cp find-and-manage-package.sh /usr/local/bin/
    sudo cp find-comprehensive.sh /usr/local/bin/
    sudo cp find-package-dupes.sh /usr/local/bin/
    
    printf "${GREEN}✓${RESET} Scripts installed to /usr/local/bin\n"
    
    # Install documentation
    printf "\n${BOLD}Installing documentation to /usr/local/share/doc...${RESET}\n"
    sudo mkdir -p /usr/local/share/doc/package-toolkit
    sudo cp README.md TOOLKIT_QUICK_REFERENCE.md FIND_DUPES_GUIDE.md \
            ARCHITECTURE_ANALYSIS.md CEDILLA_REMOVAL_GUIDE.md QUICK_REFERENCE.md \
            /usr/local/share/doc/package-toolkit/
    
    printf "${GREEN}✓${RESET} Documentation installed\n"
    
    printf "\n${GREEN}${BOLD}✓ SYSTEM INSTALLATION COMPLETE${RESET}\n"
    printf "\n${BOLD}Now available system-wide:${RESET}\n"
    printf "  find-and-manage-package.sh\n"
    printf "  find-comprehensive.sh\n"
    printf "  find-package-dupes.sh\n"
    
else
    printf "${GREEN}✓${RESET} All files ready in current directory\n"
    printf "\n${GREEN}${BOLD}✓ LOCAL SETUP COMPLETE${RESET}\n"
    printf "\n${BOLD}Use with:${RESET}\n"
    printf "  ./find-and-manage-package.sh firefox\n"
    printf "  ./find-comprehensive.sh firefox -v\n"
    printf "  ./find-package-dupes.sh --summary\n"
fi

printf "\n${BOLD}Next steps:${RESET}\n"
printf "  1. Read: ${BLUE}README.md${RESET}\n"
printf "  2. Guide: ${BLUE}TOOLKIT_QUICK_REFERENCE.md${RESET}\n"
printf "  3. Try: ${BOLD}find-and-manage-package.sh firefox${RESET}\n"

printf "\n${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"

exit 0
