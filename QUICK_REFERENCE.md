# Quick Reference: Both Scripts

## Setup (One Time)

```bash
chmod +x find-and-manage-package.sh find-comprehensive.sh
sudo cp find-and-manage-package.sh /usr/local/bin/find-package
sudo cp find-comprehensive.sh /usr/local/bin/find-package-deep
```

### Step 1: Find It

```bash
# Option A: Simple search (may miss it)
./find-and-manage-package.sh "cedilla"

# Option B: Comprehensive search (will find everything)
./find-comprehensive.sh "cedilla"

# Option C: Manual verification (guaranteed)
flatpak list --app | grep -i cedilla
find /etc -name "*cedilla*"
locate cedilla
```

### Step 2: Understand It

```bash
# See what the Flatpak app actually is
flatpak info --show-metadata dev.mariinkys.Cedilla

# See system library references (don't remove these)
sudo dpkg -S "*cedilla*" 2>/dev/null
```

### Step 3: Remove It (Correct Order)

```bash
# 1. Remove the application and its data
flatpak remove --delete-data dev.mariinkys.Cedilla

# 2. Remove system configuration
sudo rm -v /etc/profile.d/cedilla-portuguese.sh

# 3. DON'T remove /usr/lib/*/gtk-*/immodules/im-cedilla.so
#    (This is part of GTK, other apps need it)

# 4. Verify it's gone
flatpak list --app | grep -i cedilla  # Should return nothing
find /etc -name "*cedilla*"            # Should return nothing
```

---

## Script 1: `find-and-manage-package.sh` (Fast)

### Basic Usage

```bash
./find-and-manage-package.sh "pattern"
```

### Examples

```bash
# Find bash
./find-and-manage-package.sh "bash"

# Find Python (any version)
./find-and-manage-package.sh "python"

# Exact match only
./find-and-manage-package.sh "^gimp$"

# Find all lib packages
./find-and-manage-package.sh "^lib"
```

### Output Sections

1. **Installed Instances** - Where it is (apt/snap/flatpak)
2. **Removal Commands** - Copy-paste safe removal
3. **Installation Options** - How to install if missing

### When to Use

- ✅ Quick package lookup
- ✅ Standard installations only
- ✅ You trust package managers
- ✅ Speed matters

### When NOT to Use

- ❌ Looking for hidden/manual installations
- ❌ Searching for files or configs
- ❌ Auditing system state
- ❌ Finding dependencies

---

## Script 2: `find-comprehensive.sh` (Thorough)

### Basic Usage

```bash
./find-comprehensive.sh "pattern"
./find-comprehensive.sh -v "pattern"      # Verbose
./find-comprehensive.sh --layer 1 "pattern"  # Layer 1 only
```

### Layers Explained

```
L1: Package managers (apt, snap, flatpak)
L2: System config files (/etc/)
L3: System libraries (/usr/lib/, /usr/bin/, /opt/)
L4: Filesystem database (locate)
L5: User paths (~/.local/, ~/opt/)
L6: dpkg file ownership
```

### Examples

```bash
# Find everything named cedilla
./find-comprehensive.sh "cedilla"

# Verbose output (all search operations)
./find-comprehensive.sh -v "cedilla"

# Only package manager results
./find-comprehensive.sh --layer 1 "python"

# Only config files
./find-comprehensive.sh --layer 2 "vim"

# Only system libraries
./find-comprehensive.sh --layer 3 "gtk"

# Only filesystem database
./find-comprehensive.sh --layer 4 "npm"

# Only user directories
./find-comprehensive.sh --layer 5 "rustc"

# Only dpkg ownership
./find-comprehensive.sh --layer 6 "libssl"
```

### Output Interpretation

```
[L1] Package Managers → Official installations (safe to remove)
[L2] System Config   → Settings files (safe to remove)
[L3] System Libraries → Dependencies (⚠️ check before removing)
[L4] Filesystem      → All files (⚠️ may be false positives)
[L5] User Paths      → User installs (usually safe to remove)
[L6] dpkg Ownership  → Metadata (shows what owns what)
```

### When to Use

- ✅ Deep system audits
- ✅ Finding "lost" installations
- ✅ Understanding dependencies
- ✅ Debugging bloat
- ✅ Comprehensive cleanup

### When NOT to Use

- ❌ You just need a quick answer
- ❌ Speed is critical
- ❌ You want low false positives
- ❌ Automating removals (high risk)

---

## Decision Tree: Which Script?

```
Do you know the package name?
├─ YES: Is it a standard package? (apt/snap/flatpak)
│       ├─ YES: Use Script 1 (fast, safe)
│       └─ NO: Use Script 2 (thorough)
│
└─ NO: You're looking for something hidden
        Use Script 2 (comprehensive)

Is speed critical?
├─ YES: Use Script 1
└─ NO: Use Script 2 if you want to understand the system

Do you need to be 100% sure nothing is missed?
├─ YES: Use Script 2
└─ NO: Use Script 1 (package managers are reliable)
```

---

## Real-World Commands (Copy-Paste Ready)

### Find & Remove Firefox

```bash
# Find it
./find-and-manage-package.sh "firefox"

# Remove (choose one)
sudo apt remove firefox
snap remove firefox-esr
flatpak remove --delete-data org.mozilla.firefox
```

### Find & Remove All Python

```bash
# Deep search
./find-comprehensive.sh "python"

# Remove (example)
sudo apt remove python3 python3-pip
flatpak remove --delete-data org.python.Python
```

### Audit GTK (for developers)

```bash
# See all GTK installations
./find-comprehensive.sh "gtk" -v

# See GTK layer by layer
./find-comprehensive.sh --layer 1 "gtk"  # Package managers
./find-comprehensive.sh --layer 3 "gtk"  # Libraries
./find-comprehensive.sh --layer 6 "gtk"  # File ownership
```

### Find Orphaned Config Files

```bash
# Deep search for "config" anywhere
./find-comprehensive.sh --layer 2 "myapp"

# Remove orphaned files
sudo rm -v /etc/myapp*
```

### Debug: Why is my system bloated?

```bash
# See everything
./find-comprehensive.sh "." -v | less

# Count matches per layer
echo "L1:" && ./find-comprehensive.sh --layer 1 "." | wc -l
echo "L3:" && ./find-comprehensive.sh --layer 3 "." | wc -l
```

---

## Removal Safety Checklist

Before removing anything:

- [ ] I found the correct package name
- [ ] I verified it's actually installed
- [ ] I checked if other packages depend on it
- [ ] I ran the command and reviewed the output
- [ ] I have a backup/way to reinstall if needed
- [ ] I'm removing the right instance (apt/snap/flatpak)
- [ ] I'm NOT removing system libraries (L3 results)

**Never remove** anything from:
- `/usr/lib/` (unless you're 100% sure)
- `/usr/bin/` (unless you're 100% sure)
- Flatpak/snap/steam runtimes (they manage themselves)

---

## Troubleshooting

### "Scripts not found"
```bash
chmod +x find-*.sh
# Or use: bash find-and-manage-package.sh "pattern"
```

### "Locate database not updated"
```bash
sudo updatedb
# Then run layer 4 searches again
```

### "Too many results, can't find what I want"
```bash
# Use the layer option to narrow down
./find-comprehensive.sh --layer 1 "pattern"

# Or use grep to filter
./find-comprehensive.sh "pattern" | grep -i "snap\|flatpak"
```

### "Found it but the removal command doesn't work"
```bash
# Verify you're root (for apt)
sudo apt remove package

# Verify snap/flatpak are installed
which snap flatpak

# Try exact package name from search output
flatpak remove "exact-app-name-from-output"
```

---

## Performance Notes

| Operation | Time | Notes |
|-----------|------|-------|
| Script 1 basic | ~100ms | Fast, L1 only |
| Script 2 L1-L2 | ~300ms | Quick audit |
| Script 2 full | ~2-5s | Filesystem I/O |
| Script 2 + locate | ~1-2s | Database queries |
| updatedb (first run) | ~30-60s | System-wide, run once |

---

## For Developers / Automation

### Safe automated search
```bash
# Use Script 1 with known package names
./find-and-manage-package.sh "$PKG_NAME" | grep "^[^[!]"
```

### Audit without human interpretation
```bash
# Script 1 is safe for automation
# Script 2 requires manual review (too many false positives)
```

### CI/CD cleanup
```bash
# Remove known packages
for pkg in cedilla xterm build-essential; do
  ./find-and-manage-package.sh "$pkg" && \
  # (extract commands and run)
done
```

---

## Recommended Aliases

Add to `~/.bashrc`:

```bash
alias find-pkg='bash ~/path/to/find-and-manage-package.sh'
alias find-pkg-deep='bash ~/path/to/find-comprehensive.sh'
alias find-apt='find-pkg-deep --layer 1'
alias find-config='find-pkg-deep --layer 2'
alias find-libs='find-pkg-deep --layer 3'
alias find-all='find-pkg-deep -v'
```

Then:
```bash
find-pkg "bash"           # Quick search
find-all "cedilla"        # Deep audit
find-libs "gtk"           # System libraries only
find-config "vim"         # Config files only
```
