![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/trymsae.memeshell)
![Release Please](https://github.com/trymsae/MemeShell/actions/workflows/release-please.yaml/badge.svg)

# MemeShell 🗿
PowerShell module for generating memes in your terminal. 130+ templates, runs fully local at around ~10mb\
<img width="1280" height="640" alt="memeshell" src="https://github.com/user-attachments/assets/70126029-c473-4273-8aac-dddb47ef4cdf" />
<p align="center" width="100%">
  <video src="https://github.com/user-attachments/assets/1316a23a-8920-4a48-925f-c49d167c8019" width="80%" controls></video>
</p>
<p align="center" width="100%">
  <video src="https://github.com/user-attachments/assets/3736219a-7a96-4294-83d5-66e7f3da37f3" width="80%" controls></video>
</p>


## What you get

- 130+ bundled templates, all local — no rate limits, no API keys, no cap
- `New-Meme` auto-copies to clipboard on generation so you can paste immediately
- `New-Meme -manual` switch opens a GUI editor with live preview and drag-and-drop text positioning
- `Import-Meme` to add your own templates from a local file or a URL
- User templates live in `~/.memeshell/` so they survive module updates

## Installation, if you're brave enough

### From PowerShell Gallery
```powershell
Install-Module -Name trymsae.memeshell -Scope CurrentUser
```

### Manual Installation
1. Head to the [releases](https://github.com/trymsae/MemeShell/releases) and grab the newest version
2. Extract and drop it into `C:\Users\USERNAME\Documents\PowerShell\Modules`
3. Import it:
```powershell
Import-Module -Name trymsae.memeshell
```

## Usage

```powershell
# quick meme from the command line
New-Meme -template "drake" -topText "Using APIs" -bottomText "Local PowerShell memes"

# open the GUI editor (recommended)
New-Meme -template "bernie" -manual

# import a template from a file
Import-Meme -path "C:\memes\my-template.png"

# import a template straight from a URL
Import-Meme -path "https://imgflip.com/s/meme/Futurama-Fry.jpg"
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
- **Release Please**: automated semantic versioning
- **GitHub Actions**: builds on release
- **PSGallery Publishing**: auto-publishes on new releases

## Contributing

### Commit Syntax
Uses release-please for semantic versioning:

```
fix(trymsae.memeshell): resolve encoding issue
feat(trymsae.memeshell): add new meme template
feat(trymsae.memeshell)!: remove deprecated function
```

*Built with PowerShell, with an unhinged love for memes*
