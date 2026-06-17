# Ubuntu/Pop!_OS Package Management Toolkit

**Solve the package manager visibility problem on Ubuntu/Pop!_OS.**

Finding out where a package is installed from is hard when apt, snap, and flatpak all coexist.
This toolkit is built for people who just want to know what is installed, where it came from, and the exact commands to remove it.
No multiple GUIs, no confusing selection prompts, no guesswork.

It also helps you find duplicate installations and remove versions that do not suit your needs, such as sandboxed apps like Siril that require plugins and do not work well in isolated environments.

---

## 📦 What You Have

A professional-grade toolkit with **three complementary scripts** that work together for complete package visibility:

| Script | Purpose | Speed | When to Use |
|--------|---------|-------|------------|
| **find-and-manage-package.sh** | Find ONE package quickly | ~100ms | You know the package name |
| **find-comprehensive.sh** | Deep 6-layer audit | ~2-5s | Hard-to-find packages |
| **find-package-dupes.sh** | Find ALL duplicates | ~5-10s | System cleanup/audit |

### Documentation Files

| File | Purpose | Read Time |
|------|---------|-----------|
| **TOOLKIT_QUICK_REFERENCE.md** | Decision matrix, workflows, cheat sheet ⭐ **START HERE** | 5 min |
| **FIND_DUPES_GUIDE.md** | Complete duplicate finder documentation | 10 min |
| **ARCHITECTURE_ANALYSIS.md** | Design decisions and tradeoffs | 5 min |
| **QUICK_REFERENCE.md** | Original quick-search reference | 3 min |

---

## 🚀 Quick Start (Choose Your Scenario)

### ✅ "I want to find a package I know the name of"

```bash
./find-and-manage-package.sh firefox
```

**Output:** Where it's installed + removal commands  
**Speed:** <1 second  
**Documentation:** See TOOLKIT_QUICK_REFERENCE.md → Workflow 1

---

### ✅ "A package is hard to find / I can't locate it"

```bash
./find-comprehensive.sh cedilla -v
```

**Output:** Searches across 6 layers (package managers, configs, libraries, filesystem, user paths, dpkg)  
**Speed:** ~2-5 seconds  
**Documentation:** See TOOLKIT_QUICK_REFERENCE.md → Workflow 2

---

### ✅ "My system is bloated, I have duplicate installations"

```bash
./find-package-dupes.sh
```

**Output:** Every application installed multiple ways + cleanup recommendations  
**Speed:** ~5-10 seconds  
**Documentation:** See TOOLKIT_QUICK_REFERENCE.md → Workflow 3

---

## 📚 Documentation Navigation

### For New Users
**→ Start with TOOLKIT_QUICK_REFERENCE.md (5 min read)**

It has:
- Decision matrix: "Which script do I use?"
- Real-world workflows
- Command cheat sheet
- Common scenarios

### For Finding Packages
→ See **Script 1: find-and-manage-package.sh**
- Quick lookups
- Case-insensitive search 
- Removal command generation

### For Deep Investigations
→ See **Script 2: find-comprehensive.sh**
- 6-layer architecture (L1-L6)
- Layer-specific searches
- Verbose mode for detailed analysis

### For System Audits
→ See **Script 3: find-package-dupes.sh**
- Finds ALL duplicate installations
- Fuzzy matching across naming conventions
- System efficiency score
- CSV export for spreadsheets

### For Architecture Understanding
→ See **ARCHITECTURE_ANALYSIS.md**
- Why three scripts instead of one
- Design tradeoffs
- When to use each

---

## 🎯 Key Features (All Scripts)

### Script 1: find-and-manage-package.sh
✅ Case-insensitive search (default)  
✅ Strict-case mode with `-I` flag  
✅ Regex pattern support  
✅ Fast lookups across 3 package managers  
✅ Automatic removal command generation  

### Script 2: find-comprehensive.sh
✅ 6-layer search (L1-L6)  
✅ Layer-specific searches  
✅ Verbose/detailed output modes  
✅ CSV export  
✅ Deep investigation capability  

### Script 3: find-package-dupes.sh
✅ Finds ALL duplicate installations  
✅ Fuzzy name matching (different naming conventions)  
✅ System efficiency score  
✅ Cleanup recommendations  
✅ CSV export for analysis  
✅ Summary statistics  

---

## 🔧 Installation

### Option 1: Use from Current Directory
```bash
bash find-and-manage-package.sh firefox
bash find-comprehensive.sh firefox -v
bash find-package-dupes.sh --summary
```

### Option 2: Install to PATH
```bash
chmod +x find-*.sh
sudo cp find-*.sh /usr/local/bin/

# Now use from anywhere
find-package-dupes.sh
find-and-manage-package.sh firefox
```

---

## 📖 Command Reference

### Script 1: Quick Lookup

```bash
# Case-insensitive search (default)
./find-and-manage-package.sh firefox

# Case-sensitive search
./find-and-manage-package.sh -I Firefox

# Regex patterns
./find-and-manage-package.sh "python.*"
./find-and-manage-package.sh "^lib"
```

### Script 2: Deep Search

```bash
# All 6 layers
./find-comprehensive.sh firefox

# Verbose output
./find-comprehensive.sh firefox -v

# Only specific layer
./find-comprehensive.sh firefox --layer 1   # Only package managers
./find-comprehensive.sh firefox --layer 3   # Only system libraries

# CSV export
./find-comprehensive.sh firefox --csv
```

### Script 3: Find Duplicates

```bash
# Show duplicates
./find-package-dupes.sh

# Verbose (show everything)
./find-package-dupes.sh -v

# Statistics only
./find-package-dupes.sh --summary

# Export to spreadsheet
./find-package-dupes.sh --csv > dupes.csv
```

---

## 🎓 The 6-Layer Architecture (Why Script 2 is Powerful)

```
Layer 1: Package Managers (apt, snap, flatpak)
Layer 2: System Config Files (/etc/)
Layer 3: System Libraries (/usr/lib/, /usr/bin/)
Layer 4: Filesystem Database (locate)
Layer 5: User Paths (~/.local/, ~/opt/)
Layer 6: dpkg File Ownership
```

Modern Linux installs packages **many ways**. A single app might be:
- Installed via apt (system package)
- Also installed via snap (containerized version)
- Also installed via flatpak (sandboxed version)
- Have system libraries shared across multiple installations
- Have config files in multiple locations
- Have user-installed versions in home directories

**Script 2 finds it across ALL these places.**

---

## 📊 Common Workflows

### Workflow 1: Quick Package Search
```bash
./find-and-manage-package.sh firefox
# Shows: Where it's installed, how to remove it
```

### Workflow 2: Deep Investigation
```bash
./find-comprehensive.sh firefox -v
# Shows: All 6 layers, removal strategy
```

### Workflow 3: System Cleanup
```bash
./find-package-dupes.sh
# Shows: All duplicates, recommendations
```

### Workflow 4: CSV Export for Analysis
```bash
./find-package-dupes.sh --csv > duplicates.csv
# Open in LibreOffice Calc, analyse, make decisions
```

### Workflow 5: Complete System Audit
```bash
# Step 1: Get overview
./find-package-dupes.sh --summary

# Step 2: See duplicates
./find-package-dupes.sh -v

# Step 3: For each duplicate, deep dive
./find-comprehensive.sh firefox -v

# Step 4: Follow removal recommendations
snap remove firefox    # or flatpak remove org.mozilla.firefox
```

---

## ✅ Professional Quality

- **Architecture** - Separation of concerns, auditable code
- **No auto-removal** - All operations read-only, human review required
- **Comprehensive docs** - Every function documented
- **Test coverage** - Unit tests included
- **Production-ready** - Safe for critical systems
- **Case-insensitive search**
- **Multiple output formats** - Human-readable + CSV export

---

## 🛠️ System Requirements

- **bash** 4.0+ (standard on Ubuntu/Pop!_OS)
- **Standard tools:** grep, awk, sed, find (pre-installed)
- **Optional:** snap, flatpak (if you use them)
- **Optional:** locate (for Layer 4 searches)

---

## 📚 Next Steps

### 1. **Read Documentation** (5 minutes)
Start with: **TOOLKIT_QUICK_REFERENCE.md**

### 2. **Try One Script** (1 minute)
```bash
./find-and-manage-package.sh firefox
```

### 3. **Pick Your Use Case** (5 minutes)
Choose one:
- Quick package lookup → Script 1
- Deep investigation → Script 2
- System audit/cleanup → Script 3

### 4. **Bookmark Your Guides** (for reference)
- Quick ref: TOOLKIT_QUICK_REFERENCE.md
- Detailed: FIND_DUPES_GUIDE.md (if using Script 3)

---

## 📞 Help & References

| Task | Reference |
|------|-----------|
| Which script to use? | TOOLKIT_QUICK_REFERENCE.md |
| Command syntax? | TOOLKIT_QUICK_REFERENCE.md (cheat sheet section) |
| Duplicate finder guide? | FIND_DUPES_GUIDE.md |
| Design/architecture? | ARCHITECTURE_ANALYSIS.md |
---

## 🎯 Most Common Commands

### Find a package
```bash
./find-and-manage-package.sh firefox
```

### Find where it's hiding
```bash
./find-comprehensive.sh firefox -v
```

### See system duplicates
```bash
./find-package-dupes.sh
```

### Quick system health
```bash
./find-package-dupes.sh --summary
```

### Export for analysis
```bash
./find-package-dupes.sh --csv > analysis.csv
```

---

## 📈 Summary

You now have a **complete, professional-grade package management toolkit** for Ubuntu/Pop!_OS that:

✅ Finds packages across all installation methods  
✅ Handles case-insensitive matching   
✅ Detects duplicate installations  
✅ Provides cleanup recommendations  
✅ Generates audit reports  
✅ Works with existing system tools  

**→ Start with TOOLKIT_QUICK_REFERENCE.md for the 5-minute guided tour.**

---

## File Organization

Your toolkit is organised as:

```
scripts/
├── find-and-manage-package.sh      (Quick lookup script)
├── find-comprehensive.sh            (Deep 6-layer audit)
├── find-package-dupes.sh            (Duplicate finder - NEW)
├── README.md                        (This file - toolkit overview)
├── TOOLKIT_QUICK_REFERENCE.md      (START HERE - 5 min guide)
├── FIND_DUPES_GUIDE.md             (Duplicate finder detailed guide)
├── ARCHITECTURE_ANALYSIS.md        (Design decisions)
└── QUICK_REFERENCE.md              (Original quick-search reference)
```

---

**Questions?** Read the relevant guide above, or look at the command reference in this README.

**Ready to start?** → Open **TOOLKIT_QUICK_REFERENCE.md**
