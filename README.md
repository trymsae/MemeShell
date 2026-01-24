![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/trymsae.memeshell)
![Release Please](https://github.com/trymsae/MemeShell/actions/workflows/release-please.yaml/badge.svg)

# MemeShell 🗿

**MemeShell** is a PowerShell module that brings maximum dankness to your terminal. Generate crispy memes locally with your own templates - no APIs, no cap, just pure PowerShell chaos.

## Features

- **Local Meme Generation**: 130+ templates included, all stored locally (no external API calls)
- **Multi-Line Text Support**: Add 2-6 text lines per meme with full control
- **GUI Manual Mode**: Interactive editor with live preview
- **X/Y Position Controls**: Precise text placement with drag-and-drop support
- **Clipboard Integration**: Automatically copies memes to clipboard for instant sharing
- **Classic CLI Mode**: Quick meme generation via command line parameters

## Installation, if you're brave enough

### From PowerShell Gallery
```powershell
Install-Module -Name trymsae.memeshell -Scope CurrentUser
```

### Manual Installation
1. Head to the [releases](https://github.com/trymsae/MemeShell/releases) and download the newest version.
2. Extract the content and import to your module-folder. 'C:\users\USERNAME\Documents\Powershell\Modules'
3. Import module:
```Powershell
Import-Module -Name trymsae.memeshell
```

## Usage

### Quick Start - make memes on the fly
```powershell
# Generate a meme with top/bottom text
New-Meme -template "drake" -topText "Using APIs" -bottomText "Local PowerShell memes"

# Or use the alias
meme -template "distracted-boyfriend" -topText "Me" -bottomText "MemeShell"
```

## Development

### Project Structure
```
MemeShell/
├── trymsae.memeshell/
│   ├── src/               # Source files
│   ├── templates/         # Meme template images
│   ├── build/             # Build scripts
│   └── release/           # Built module (generated)
└── .github/workflows/     # CI/CD automation
```

### CI/CD Pipeline - pipeline straight to ur mom
- **Release Please**: Automated semantic versioning
- **GitHub Actions**: Automated builds on releases
- **PSGallery Publishing**: Auto-publish to PowerShell Gallery on new releases

## Contributing

### Commit Syntax
This project uses semantic versioning via release-please. Format commits like:

```
feat(trymsae.memeshell): add new meme template
fix(trymsae.memeshell): resolve encoding issue
feat(trymsae.memeshell)!: remove deprecated function
```

*Built with PowerShell, with an unhinged love for memes* 