# find-package-dupes.sh - Duplicate Package Finder

## Purpose

Audit your entire Ubuntu/Pop!_OS system to find applications installed **more than once** across different package managers (apt, snap, flatpak). Shows exactly which duplicates exist and recommends which to keep.

## Problem It Solves

Modern Linux has fragmented package distribution. You might accidentally install Firefox both via apt AND snap, Python via apt AND snap, etc. Each duplicate:
- Uses extra disk space
- Creates confusion about which version to update
- Makes system maintenance harder
- Wastes system resources

**Example:**
```
$ ./find-package-dupes.sh

DUPLICATE PACKAGES FOUND: 3

✓ DUPE  apt:firefox              snap:firefox
✓ DUPE  apt:python3              snap:python3
✓ DUPE  apt:gimp                 flatpak:org.gimp.GIMP
```

## Installation

```bash
chmod +x find-package-dupes.sh

# Optional: copy to PATH for global access
sudo cp find-package-dupes.sh /usr/local/bin/find-dupes
```

## Usage

### Basic Usage (Find Duplicates Only)

```bash
./find-package-dupes.sh
```

Output shows:
- All applications installed via multiple package managers
- Which package managers have each duplicate
- Installation locations
- Cleanup recommendations

### Verbose Mode (See Everything)

```bash
./find-package-dupes.sh -v
```

Shows:
- Full package inventory from each manager
- All installation counts
- Duplicates (if any)
- Non-duplicates (packages only installed once)

### Summary Statistics Only

```bash
./find-package-dupes.sh --summary
```

Quick audit without listing packages:
```
Installation Counts:
  APT:           866 packages
  SNAP:           12 packages
  FLATPAK:         3 packages
  ─────────────────────────
  TOTAL:         881 packages

Duplication Analysis:
  Applications installed    4 times (multiple ways)
  Unique applications:     877
  Efficiency score:       99.5% (no dupes = 100%)
```

### CSV Export (For Analysis)

```bash
./find-package-dupes.sh --csv > duplicates.csv
```

Output suitable for spreadsheet analysis:
```
manager1,package1,manager2,package2,manager3,package3
apt,firefox,snap,firefox
apt,python3,snap,python3
apt,gimp,flatpak,org.gimp.GIMP
```

### Write Results to File

```bash
./find-package-dupes.sh -o audit-results.txt
```

## Output Interpretation

### Duplicate Entry

```
✓ DUPE  apt:firefox              snap:firefox              flatpak:org.mozilla.firefox
```

Meaning: Firefox is installed three times via different package managers.

### Color Coding

| Color | Manager | Meaning |
|-------|---------|---------|
| 🟢 Green | APT | System package (tightest integration) |
| 🔵 Blue | FLATPAK | Portable containerized app |
| 🔷 Cyan | SNAP | Confined, auto-updating app |

### Efficiency Score

```
Efficiency score: 95.5% (no dupes = 100%)
```

Percentage of unique applications vs. total installations.
- 100% = Perfect (no duplicates)
- 95-99% = Good (minimal duplication)
- 90-95% = Fair (some cleanup recommended)
- <90% = Needs work (significant duplication)

## Understanding Package Managers

### APT (System Packages)

```bash
$ apt list --installed | head -5
adduser/focal,now 3.118 all
adwaita-icon-theme/focal,now 3.36.0-2ubuntu1 all
apt/focal-updates,now 2.0.2ubuntu0.4 all
```

**Pros:**
- Native system integration
- Part of base OS updates
- Tight OS dependencies

**Cons:**
- May have older versions
- Slower release cycle

**Use for:** System tools, libraries, development packages

### SNAP (Containerized Apps)

```bash
$ snap list
Name                  Version   Rev  Tracking Publisher      Notes
firefox               91.0.1    1141 stable   mozilla        -
vscode                1.60.1    56   stable   vscode         -
```

**Pros:**
- Always latest version (auto-updates weekly)
- Works across distros
- Isolated from system (safer)

**Cons:**
- Slower startup (container overhead)
- Larger disk footprint
- Confinement limitations

**Use for:** Desktop apps you want current, security-sensitive apps

### FLATPAK (Portable Containers)

```bash
$ flatpak list --app
Name             Application ID             Version Branch  Remotes
GIMP             org.gimp.GIMP              2.10.28 stable  flathub
Blender          org.blender.Blender       3.0.0   stable  flathub
```

**Pros:**
- Cross-distro compatible
- Excellent sandboxing
- Access to newer software
- Works on older systems

**Cons:**
- Slowest startup
- Largest install size
- More resource overhead

**Use for:** Bleeding-edge software, pre-releases, security-critical apps

## Cleanup Recommendations

### General Strategy

1. **Keep system packages in APT** - These have system-wide integration
2. **Remove from SNAP if you have APT** - Snap is slower, uses more space
3. **Use FLATPAK only when APT doesn't have the app** - For sandboxing or pre-releases

### Specific Examples

#### Firefox

```bash
# If you have both apt and snap:
apt-cache policy firefox        # Check apt version
snap info firefox              # Check snap version

# Remove snap version (apt is better)
snap remove firefox

# Verify
which firefox                  # Should be /usr/bin/firefox
```

#### Python

```bash
# If you have both apt and snap python3:

# Keep APT version (system tools depend on it)
snap remove python3            # Remove snap version

# Verify
python3 --version              # Should use apt version
```

#### GIMP

```bash
# If you have both apt and flatpak gimp:

# Option A: Keep APT (better integration)
flatpak remove org.gimp.GIMP

# Option B: Keep FLATPAK (isolates from system)
sudo apt remove gimp

# If keeping flatpak, create launcher
flatpak run org.gimp.GIMP &    # Or use GUI launcher
```

### Bulk Cleanup Script

```bash
# List all duplicates and their removal commands
./find-package-dupes.sh | grep "sudo apt remove\|snap remove\|flatpak remove"

# Then run each command individually (safer than bulk removal)
snap remove firefox
snap remove python3
flatpak remove org.gimp.GIMP
```

## Advanced Usage

### Analyze Over Time

```bash
# Create audit snapshots
for date in {1..7}; do
  ./find-package-dupes.sh --csv > audit-day-$date.csv
done

# Compare trends
diff audit-day-1.csv audit-day-7.csv
```

### Monitor System Health

```bash
# Check efficiency daily
./find-package-dupes.sh --summary | grep "Efficiency score"

# Alert if efficiency drops below 95%
SCORE=$(./find-package-dupes.sh --summary | grep "Efficiency" | awk '{print $NF}' | sed 's/%//')
[[ $(echo "$SCORE < 95" | bc) -eq 1 ]] && echo "WARNING: Duplication increasing!"
```

### Integration with Monitoring

```bash
# Add to crontab for weekly audit
0 2 * * 0 /path/to/find-package-dupes.sh >> /var/log/package-audit.log
```

## Output Example (With Duplicates)

```
================================================================================
  PACKAGE AUDIT SUMMARY
================================================================================

Installation Counts:
  APT:                      866 packages
  SNAP:                      12 packages
  FLATPAK:                    3 packages
  ─────────────────────────
  TOTAL:                    881 packages

Duplication Analysis:
  Applications installed       4 times (multiple ways)
  Unique applications:       877
  Efficiency score:        99.5% (no dupes = 100%)

================================================================================
  DUPLICATE PACKAGES FOUND: 4
================================================================================

Applications installed via multiple package managers:

✓ DUPE  apt:firefox                snap:firefox
✓ DUPE  apt:python3                snap:python3
✓ DUPE  apt:gimp                   flatpak:org.gimp.GIMP
✓ DUPE  apt:blender                snap:blender

================================================================================
  CLEANUP RECOMMENDATIONS
================================================================================

For each duplicate, decide which installation to keep based on your needs:

APT (system package)
  ✓ Tightest OS integration
  ✓ Automatic with system updates
  ✗ May be older versions
  → Keep for: system tools, libraries, development packages

SNAP (confined, auto-updating)
  ✓ Latest version always
  ✓ Automatic weekly updates
  ✗ Slightly slower startup
  → Keep for: desktop apps you want current

FLATPAK (portable sandbox)
  ✓ Cross-distribution compatible
  ✓ Excellent sandbox isolation
  ✗ Slower startup, larger size
  → Keep for: bleeding-edge or security-sensitive apps

RECOMMENDED REMOVAL STRATEGY:
  1. Keep system tools and libraries in APT
  2. Remove from SNAP if you also have APT
  3. Use FLATPAK for apps not in APT
```

## How It Works (Technical Details)

### Package Enumeration

```bash
# APT: Read from dpkg database
dpkg -l | grep "^ii" | awk '{print $2}'

# SNAP: Query snap manager
snap list | awk 'NR>1 {print $1}'

# FLATPAK: Query flatpak system
flatpak list --app | awk 'NR>1 {print $2}'
```

### Name Normalization

The script normalizes package names to match duplicates despite naming inconsistencies:

```
Reverse domain notation:
  org.mozilla.firefox → firefox
  org.gimp.GIMP → gimp
  
Hyphen/underscore normalization:
  python3-pip → python, pip
  vim-nox → vim
  
Version suffix removal:
  python3.10 → python3
  libssl1.1 → libssl
```

### Fuzzy Matching

Duplicates identified by:
1. **Exact match** - Same normalized name
2. **Base name match** - Same core package name
3. **Keyword overlap** - At least 2 shared keywords (requires both conditions)

Example:
```
firefox (apt) matches firefox (snap) → DUPE
org.mozilla.firefox (flatpak) shares "firefox" + "org" → DUPE
```

## Common Issues

### "snap not installed"

Snap is not available on your system. This is fine—the script will audit apt and flatpak only.

```bash
# Install snap if desired:
sudo apt install snapd
```

### "No duplicates found!"

Your system is optimized! You're not installing applications multiple ways. Good job.

### Slow on First Run

First enumeration takes time (scanning thousands of packages). Subsequent runs cache faster.

### False Positives

The fuzzy matching is conservative. It requires keyword overlap to prevent false positives. If you see an unexpected duplicate, it's likely real (two versions of same app).

## Troubleshooting

### Check individual managers manually:

```bash
# APT packages
apt list --installed | wc -l

# SNAP packages  
snap list | wc -l

# FLATPAK packages
flatpak list --app | wc -l
```

### Debug matching:

```bash
# Add verbose output to script
bash -x find-package-dupes.sh -v 2>&1 | head -100
```

## Security Considerations

- Script only **reads** package information (no modifications)
- Requires no elevated privileges
- Safe to run anytime
- Does not access network or external services

## Performance

- First run: 2-5 seconds (enumerates all packages)
- Subsequent runs: <1 second (if no new packages)
- Memory: ~10MB (stores package names in memory)

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (duplicates found or not) |
| 1 | Error (invalid arguments, missing tools) |

## Integration Examples

### Email Daily Audit

```bash
#!/bin/bash
AUDIT=$(/path/to/find-package-dupes.sh --summary)
echo "$AUDIT" | mail -s "Daily Package Audit" admin@example.com
```

### Slack Notification

```bash
#!/bin/bash
SCORE=$(./find-package-dupes.sh --summary | grep "Efficiency" | awk '{print $NF}')
if [[ $(echo "$SCORE < 95" | bc) -eq 1 ]]; then
  curl -X POST -d "Package efficiency dropped to $SCORE" webhook.slack.com/...
fi
```

## Next Steps

After finding duplicates:

1. **Review** - Decide which version to keep for each duplicate
2. **Test** - Verify the version you're keeping works well
3. **Remove** - Use the provided commands to remove unwanted versions
4. **Verify** - Confirm removal was successful
5. **Document** - Note which version you kept and why

## Support

For issues or improvements:

```bash
# Check script version
grep "^# VERSION" find-package-dupes.sh

# Enable debug mode
bash -x find-package-dupes.sh

# Report issues with full output
./find-package-dupes.sh -v > audit-report.txt
```
