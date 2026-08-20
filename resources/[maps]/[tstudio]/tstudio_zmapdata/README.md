# TStudio Door Tuning Resource

A GTA V FiveM resource for advanced door tuning functionality developed by TStudio3d.

## 📁 Project Structure

```
tstudio_doortuning/
├── README.md                           # This file
├── fxmanifest.lua                     # FiveM resource manifest
├── gta5.meta                          # GTA V data file configuration
├── doortuning.ymt                     # Door tuning configuration
├── heightmap.dat                      # Water level data (enables swimming anywhere)
└── audio/
    ├── tstudio_door_game.dat151.nametable  # Audio name table
    └── tstudio_door_game.dat151.rel        # Audio relations file
```

## 🚀 For Multimedia Team Members

### Getting Started

1. **Clone the Repository**
   ```bash
   git clone https://github.com/TStudio3d/tstudio_doortuning.git
   cd tstudio_doortuning
   ```

2. **Switch to Development Branch**
   ```bash
   git checkout dev
   git pull origin dev
   ```

### 🌿 Working with Feature Branches

#### Creating a New Feature Branch

Always create feature branches from the `dev` branch, not from `main`. This ensures a clean workflow and easier collaboration.

```bash
# 1. Make sure you're on the dev branch
git checkout dev

# 2. Pull the latest changes
git pull origin dev

# 3. Create your feature branch (use descriptive names)
git checkout -b feature/your-feature-name

# Examples of good branch names:
# feature/audio-enhancement
# feature/door-animation-fix
# feature/new-sound-effects
# bugfix/door-sync-issue
# improvement/performance-optimization
```

#### Working on Your Feature

```bash
# 1. Make your changes to files
# 2. Check what files you've modified
git status

# 3. Add your changes
git add .
# or add specific files
git add filename.ext

# 4. Commit your changes with a descriptive message
git commit -m "Add new door sound effects for luxury vehicles"

# 5. Push your feature branch to GitHub
git push -u origin feature/your-feature-name
```

#### Submitting Your Work

1. **Push your feature branch** to GitHub
2. **Create a Pull Request** from your feature branch to the `dev` branch
3. **Request review** from team leads
4. **Merge** will be handled by team leads after review

#### Keeping Your Feature Branch Updated

```bash
# While working on your feature, regularly sync with dev branch
git checkout dev
git pull origin dev
git checkout feature/your-feature-name
git merge dev
```

### 📋 Branch Strategy

- **`main`** - Production-ready code, stable releases
- **`dev`** - Development branch, integration of new features
- **`feature/*`** - Individual feature branches created from `dev`
- **`bugfix/*`** - Bug fix branches created from `dev`
- **`hotfix/*`** - Critical fixes that go directly to `main`

### 🎯 File Modification Guidelines

#### Audio Files (`audio/` directory)
- **What they do**: Handle door sound effects and audio cues
- **When to modify**: Adding new sounds, adjusting audio timing, fixing audio bugs
- **Format**: DAT151 format (GTA V audio format)

#### Configuration Files
- **`fxmanifest.lua`**: Resource configuration for FiveM
- **`gta5.meta`**: GTA V data file references and configurations
- **`doortuning.ymt`**: Door behavior and tuning parameters

#### Data Files
- **`heightmap.dat`**: Water level configuration that enables swimming anywhere on the map
  - ⚠️ **Note**: This file is not directly related to door tuning but is included here because the resource requires the `gta5.meta` file structure
- **`doortuning.ymt`**: Core door tuning configurations

### 🛠️ Common Tasks

#### Adding New Audio Files
1. Place new audio files in the `audio/` directory
2. Update references in `gta5.meta` if needed
3. Test in-game before committing

#### Modifying Door Behavior
1. Edit `doortuning.ymt` for door parameters
2. Update `gta5.meta` if adding new references
3. Test functionality thoroughly

#### Performance Optimization
1. Check file sizes and optimize where possible
2. Ensure compatibility with existing configurations
3. Document any breaking changes

#### Understanding the Heightmap File
The `heightmap.dat` file included in this resource serves a specific purpose:
- **Primary function**: Configures water levels across the entire GTA V map
- **Effect**: Allows players to swim anywhere, regardless of terrain elevation
- **Why it's here**: Despite being unrelated to door tuning, this file is included because:
  - The resource structure requires the `gta5.meta` configuration file
  - The meta file provides the framework needed for both door tuning and water level modifications
  - Bundling them together reduces server resource overhead
- **⚠️ Important**: Do not modify this file unless you understand water level mechanics

### 🔍 Testing Your Changes

1. **Local Testing**: Always test your changes locally before pushing
2. **Documentation**: Update relevant documentation for new features
3. **Compatibility**: Ensure changes don't break existing functionality

### 📞 Getting Help

- **Team Lead**: Contact for major changes or architecture decisions
- **Documentation**: Check this README and inline code comments
- **Issues**: Use GitHub Issues for bug reports and feature requests

### 🚫 What NOT to Do

- ❌ Don't commit directly to `main` branch
- ❌ Don't push broken or untested code
- ❌ Don't modify files without understanding their purpose
- ❌ Don't forget to pull latest changes before starting work

### 📝 Commit Message Guidelines

Use clear, descriptive commit messages:

```bash
# Good examples:
git commit -m "Add luxury vehicle door sound effects"
git commit -m "Fix door animation timing issue"
git commit -m "Optimize audio file loading performance"
git commit -m "Update door tuning parameters for sports cars"

# Bad examples:
git commit -m "fix stuff"
git commit -m "changes"
git commit -m "audio"
```

### 🔄 Quick Reference Commands

```bash
# Clone and setup
git clone https://github.com/TStudio3d/tstudio_doortuning.git
cd tstudio_doortuning
git checkout dev

# Create feature branch
git checkout -b feature/my-new-feature

# Save your work
git add .
git commit -m "Descriptive commit message"
git push -u origin feature/my-new-feature

# Update from dev
git checkout dev
git pull origin dev
git checkout feature/my-new-feature
git merge dev

# Check status
git status
git log --oneline
git branch -a
```

---

## 📄 License

This project is proprietary to TStudio3d. All rights reserved.

## 👥 Contributors

- TStudio3d Team
- Multimedia Team Members

---

**Remember**: When in doubt, ask! It's better to clarify than to break something. Happy coding! 🚀
