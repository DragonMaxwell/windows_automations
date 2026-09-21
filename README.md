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

## Notes

- Review scripts before running them.
- Some scripts modify Registry policies, services, scheduled tasks, and Windows settings.
- A restart may be required after some changes.
- Do not store passwords, tokens, private keys, or credentials directly in the repository.

## Version

### 0.0.1

Initial version.
