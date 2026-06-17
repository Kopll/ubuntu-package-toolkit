# Complete Package Management Toolkit - Quick Reference

## Three Scripts, One Goal: Total System Clarity

| Script | Purpose | Speed | Use When |
|--------|---------|-------|----------|
| **find-and-manage-package.sh** | Find ONE package | ~100ms | You know the package name |
| **find-comprehensive.sh** | Deep audit of one package | ~2-5s | Package hard to find/hidden |
| **find-package-dupes.sh** | Find ALL duplicates | ~5s | Want system-wide audit |

---

## Workflows

### Workflow 1: Quick Search (You Know The Package Name)

```bash
# Find a specific package quickly
./find-and-manage-package.sh firefox

# Output:
# ✓ FOUND: firefox (apt)          @ /usr/bin/firefox
# ✓ FOUND: firefox (snap)         @ /snap/firefox
# REMOVAL COMMANDS:
#   $ sudo apt remove firefox
#   $ snap remove firefox
```

**Time:** <1 second  
**Best for:** When you remember the package name

---

### Workflow 2: Deep Investigation (Package Hard to Find)

```bash
# Comprehensive search when quick search fails
./find-comprehensive.sh "cedilla" -v

# Output shows all layers:
# [L1] Package Managers
# [L2] System Config Files
# [L3] System Libraries
# [L4] Filesystem Database
# [L5] User Paths
# [L6] dpkg File Ownership
```

**Time:** 2-5 seconds  
**Best for:** When you know a package exists but can't find it

---

### Workflow 3: System Audit (Find All Duplicates)

```bash
# Get complete picture of your system
./find-package-dupes.sh

# Output:
# DUPLICATE PACKAGES FOUND: 3
# ✓ DUPE: apt:firefox          snap:firefox
# ✓ DUPE: apt:python3          snap:python3
# ✓ DUPE: apt:gimp             flatpak:org.gimp.GIMP
```

**Time:** 5-10 seconds  
**Best for:** Cleaning up bloat and understanding system state

---

## Combined Workflows

### Scenario: "My System is Slow, What's Using Space?"

```bash
# Step 1: Get overview of duplicates
./find-package-dupes.sh --summary

# Output shows efficiency score and duplicate count

# Step 2: See what duplicates exist
./find-package-dupes.sh

# Step 3: For each duplicate, decide which to keep
./find-comprehensive.sh firefox -v

# Step 4: Look at removal recommendations
# (script shows them automatically)

# Step 5: Remove unwanted versions one at a time
snap remove firefox
flatpak remove org.mozilla.firefox
```

---

### Scenario: "I Want to Clean Up, Show Me Everything"

```bash
# Stage 1: Audit
./find-package-dupes.sh -v > full-audit.txt

# Stage 2: For each dupe, investigate deeper
./find-comprehensive.sh python3 -v > python3-audit.txt
./find-comprehensive.sh firefox -v > firefox-audit.txt

# Stage 3: Export for analysis
./find-package-dupes.sh --csv > duplicates.csv

# Stage 4: Cross-reference in spreadsheet, make decisions

# Stage 5: Execute removals
./find-package-dupes.sh | grep "remove" | bash  # (careful!)
# Better: run commands one at a time
snap remove firefox
```

---

### Scenario: "I Found Package X, Now What?"

```bash
# Find it
./find-and-manage-package.sh gimp

# See if it's duplicated
./find-package-dupes.sh | grep gimp

# If duplicated, deep dive
./find-comprehensive.sh gimp -v

# Decide which to keep, execute removal
flatpak remove org.gimp.GIMP  # or sudo apt remove gimp
```

---

## Command Cheat Sheet

### find-and-manage-package.sh

```bash
# Case-insensitive search (default)
./find-and-manage-package.sh firefox

# Case-sensitive search  
./find-and-manage-package.sh -I Firefox

# Regex patterns
./find-and-manage-package.sh "python.*"
./find-and-manage-package.sh "^lib"
```

### find-comprehensive.sh

```bash
# Full search all layers
./find-comprehensive.sh firefox

# Verbose output
./find-comprehensive.sh firefox -v

# Only package managers (L1)
./find-comprehensive.sh firefox --layer 1

# Only config files (L2)
./find-comprehensive.sh firefox --layer 2

# Only system libraries (L3)
./find-comprehensive.sh firefox --layer 3

# Only filesystem (L4)
./find-comprehensive.sh firefox --layer 4

# Only user paths (L5)
./find-comprehensive.sh firefox --layer 5

# CSV output
./find-comprehensive.sh firefox --csv
```

### find-package-dupes.sh

```bash
# Show duplicates
./find-package-dupes.sh

# Verbose (show everything)
./find-package-dupes.sh -v

# Summary statistics
./find-package-dupes.sh --summary

# CSV export
./find-package-dupes.sh --csv > dupes.csv

# Write to file
./find-package-dupes.sh -o audit.txt

# Combined
./find-package-dupes.sh -v --csv > full-audit.csv
```

---

## Decision Matrix: Which Script?

```
Do you know the package name?
├─ YES
│  └─ Quick search: ./find-and-manage-package.sh
│
└─ NO
   └─ Search by part of name: ./find-comprehensive.sh

Do you want to see ALL packages?
├─ YES → ./find-package-dupes.sh
└─ NO  → ./find-and-manage-package.sh

Are you doing system cleanup?
└─ YES → Start with ./find-package-dupes.sh

Need to drill deep on one package?
└─ YES → Use ./find-comprehensive.sh -v
```

---

## Example: Complete Cleanup Session

```bash
#!/bin/bash
# Complete system cleanup workflow

echo "=== SYSTEM AUDIT ==="
./find-package-dupes.sh

echo -e "\n=== DETAILED DUPLICATES ==="
./find-package-dupes.sh | grep "DUPE" | awk '{print $3}' | while read pkg; do
  echo -e "\n--- $pkg ---"
  ./find-comprehensive.sh "$pkg"
done

echo -e "\n=== EXPORT FOR REVIEW ==="
./find-package-dupes.sh --csv > cleanup-candidates.csv
echo "Exported to cleanup-candidates.csv"

echo -e "\n=== FINAL SUMMARY ==="
./find-package-dupes.sh --summary
```

---

## Performance Tips

### Speed Up find-package-dupes.sh

If auditing large systems repeatedly:

```bash
# Cache current state
./find-package-dupes.sh > baseline.txt

# Later, check only new duplicates
./find-package-dupes.sh > current.txt
diff baseline.txt current.txt
```

### Parallel Searches

Investigate multiple packages in parallel:

```bash
./find-comprehensive.sh firefox -v > firefox-audit.txt &
./find-comprehensive.sh python3 -v > python3-audit.txt &
./find-comprehensive.sh gimp -v > gimp-audit.txt &
wait
```

### Cron Job for Weekly Audit

```bash
# /etc/cron.d/package-audit
0 2 * * 0 /home/user/scripts/find-package-dupes.sh --summary >> /var/log/weekly-audit.log
```

---

## Safety Guidelines

### Before Running Any Removal

```bash
# Step 1: Find package
./find-and-manage-package.sh firefox

# Step 2: Review what will be removed
# (look at the removal commands output)

# Step 3: Test with ONE version first
snap remove firefox
# Verify it still works: firefox (should still open from apt)

# Step 4: Only then remove others if needed
sudo apt remove firefox  # (if you decided to keep snap)
```

### Recovery If Something Goes Wrong

```bash
# If you removed the wrong version:
./find-and-manage-package.sh firefox
# (shows installation options)

# Reinstall:
sudo apt install firefox
# or
snap install firefox
# or
flatpak install org.mozilla.firefox
```

---

## Integration Examples

### Monitor for New Duplicates

```bash
#!/bin/bash
# Run daily, alert if new duplicates appear

CURRENT=$(./find-package-dupes.sh --summary | grep "Applications installed")
BASELINE="Applications installed       0 times"

if [[ "$CURRENT" != "$BASELINE" ]]; then
  echo "WARNING: New duplicates detected!" | mail -s "Package Alert" you@example.com
fi
```

### Dashboards and Reporting

```bash
# Generate HTML report
{
  echo "<html><body><pre>"
  ./find-package-dupes.sh -v
  echo "</pre></body></html>"
} > audit-$(date +%Y-%m-%d).html
```

---

## Troubleshooting

### Script Says "Not Found" But I Know It's Installed

→ Use `./find-comprehensive.sh` instead (searches 6 layers vs. 3)

### Getting False Positives

→ Use `-I` (strict case) flag to reduce fuzzy matches

### Performance Slow

→ Use `--summary` mode for just statistics

### Need to Debug

→ Use `-v` (verbose) flag to see all operations

---

## File Organization

Recommend organising scripts and outputs:

```
~/scripts/
├── find-and-manage-package.sh
├── find-comprehensive.sh
├── find-package-dupes.sh
└── README.md

~/audits/
├── 2024-01-15-full-audit.txt
├── 2024-01-15-duplicates.csv
└── 2024-01-22-cleanup-session.txt
```

---

## Summary Table

| Task | Command | Time | Output |
|------|---------|------|--------|
| Find one package | `./find-and-manage-package.sh firefox` | <1s | Locations + removal commands |
| Deep search | `./find-comprehensive.sh firefox -v` | ~3s | 6 layers of detail |
| Find all dupes | `./find-package-dupes.sh` | ~5s | All duplicates + recommendations |
| System stats | `./find-package-dupes.sh --summary` | ~2s | Efficiency score + counts |
| Export data | `./find-package-dupes.sh --csv` | ~5s | CSV format for spreadsheets |

---

## Next Steps

1. **Setup:** Copy scripts to `~/.local/bin/` or `/usr/local/bin/`
2. **Learn:** Review QUICK_REFERENCE.md and individual guides
3. **Audit:** Run `./find-package-dupes.sh` to baseline your system
4. **Review:** Examine duplicates found and make decisions
5. **Cleanup:** Remove unwanted versions following recommendations
6. **Monitor:** Run periodic audits to catch new duplicates

---

## Questions?

Refer to individual script guides:
- **find-and-manage-package.sh** → README.md
- **find-comprehensive.sh** → ARCHITECTURE_ANALYSIS.md  
- **find-package-dupes.sh** → FIND_DUPES_GUIDE.md
