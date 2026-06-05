# Contributing to MemeShell

## Adding meme templates

The easiest way to contribute a new template is with `Import-Meme -toSource`. This drops the image directly into the repo's template folder so it gets bundled in the next release.

```powershell
# import from a local file
Import-Meme -path "C:\memes\my-template.png" -toSource

# import straight from a URL
Import-Meme -path "https://example.com/distracted-boyfriend.jpg" -toSource
```

This only works when running the module from the dev repo (not a PSGallery install). Build it locally first:

```powershell
# build the module
.\trymsae.memeshell\build\build.ps1

# load it
Import-Module .\trymsae.memeshell\release\*.psd1 -Force
```

### Image requirements

- **Formats**: jpg, jpeg, png, bmp
- **Size**: anything goes — images larger than 800px on either dimension get resized down automatically. Smaller images are left as-is.
- **Naming**: filenames get normalized to kebab-case automatically (`My Funny Cat.jpg` → `my-funny-cat.png`). Use `-name` to override.

### Commit format for new templates

```
feat(templates): add <template-name>
```

Example:
```
feat(templates): add distracted-boyfriend
```

---

## Code contributions

### Commit syntax

This project uses [release-please](https://github.com/googleapis/release-please) for automated semantic versioning. Format your commits like:

```
fix(trymsae.memeshell): what you fixed
feat(trymsae.memeshell): what you added
feat(trymsae.memeshell)!: breaking change
chore(build): build/ci stuff that doesn't affect the module version
```

### Building locally

```powershell
# build
.\trymsae.memeshell\build\build.ps1

# load
Import-Module .\trymsae.memeshell\release\*.psd1 -Force
```

### Project structure

```
MemeShell/
├── trymsae.memeshell/
│   ├── src/               # PowerShell source files (one function per file)
│   ├── templates/         # Bundled meme templates
│   │   ├── pictures/      # Template images
│   │   └── texts/         # Text files (load messages etc.)
│   ├── build/             # Build scripts
│   └── release/           # Generated module output (gitignored)
└── .github/workflows/     # CI/CD
```

Source files in `src/` get concatenated into a single `.psm1` on build — keep one function per file and name the file after the function.
