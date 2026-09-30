# Windows Setup Automation Scripts

Version: **0.0.1**

Collection of PowerShell automation scripts for Windows 10 and Windows 11 installation and post-installation tasks.

## Structure

```text
.
│   .gitignore
│   execute_scripts.cmd
│   LICENSE
│   README.md
│
└───scripts
    └───Win11_disable_telemetry.ps1
```

`execute_scripts.cmd` runs every `.ps1` file found recursively inside the `scripts` folder.

## Usage

Run:

```cmd
execute_scripts.cmd
```

Administrator privileges are requested automatically.

Execution results are saved to:

```text
script_execution.log
```

**Scripts Included:**

**01_Win11_block_internet_access_foreach_exe**

Recursively locates previously configured executable files and creates outbound Windows Firewall rules to block their internet access. It currently targets Microsoft Office applications such as Word, Excel, PowerPoint, and Access, as well as Foxit PDF Editor, preventing external connections, data transmission, and updates performed directly by those executables.

**02_Win11_disable_telemetry**

Aggressively reduces Windows 11 telemetry, diagnostic data collection, error reporting, activity history, personalized advertising, data-based suggestions, and feedback requests. It also disables services and scheduled tasks related to telemetry and the Customer Experience Improvement Program, while restricting Microsoft account usage without disabling essential components such as Windows Update, Microsoft Defender, Microsoft Store, or Windows activation.

**03_Win11_quality_of_life_custom**

Applies quality-of-life adjustments to Windows 11 without removing essential components. It disables Delivery Optimization peer-to-peer sharing, Start menu recommendations and promotional content, Web/Bing integration in Windows Search, promotional notifications, Windows Welcome Experience, setup suggestions, and OneDrive promotional warnings. Windows Update, Windows Search, and the main system components remain fully functional.

**04_Win11_debloat**

Performs broad Windows 11 cleanup focused on privacy, reducing unnecessary components, and simplifying the environment. It reduces telemetry and diagnostics, removes several AppX applications and consumer-oriented components, uninstalls OneDrive and Microsoft Edge while preserving WebView2, disables Copilot, Widgets, Game DVR, and selected Xbox services, and turns off services considered unnecessary for the configured environment. It also removes known OEM support and telemetry packages and disables automatic locking, screen saver activation, and idle sleep, while explicitly preserving important components such as Microsoft Defender, Windows Firewall, Windows Search, Microsoft Store, Windows Update, Hyper-V, WSL, and core networking features.


## Notes

- Review scripts before running them.
- Some scripts modify Registry policies, services, scheduled tasks, and Windows settings.
- A restart may be required after some changes.
- Do not store passwords, tokens, private keys, or credentials directly in the repository.

## Version

### 0.0.2

