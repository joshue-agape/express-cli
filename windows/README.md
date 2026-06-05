# Express Project Aliases – Documentation  

A practical guide to setting up Express.js project aliases in PowerShell to streamline your development workflow and boost command-line efficiency.  

## PowerShell Profile Setup  

Before using the aliases, you need to configure your PowerShell profile.  

### Check if the profile exists  

```bash
Test-Path $PROFILE
```

True → the profile already exists  
False → proceed to the next step  

### Create the profile

```bash
New-Item -Path $PROFILE -ItemType File -Force
```

### Open and edit the profile  

- Using Notepad:  

```bash
New-Item -Path $PROFILE -ItemType File -Force
```

- Or using VS Code:  

```bash
code $PROFILE
```

## Install Aliases  

Make sure the directory exists, otherwise create it:

```bash
mkdir -p "$HOME\.config\alias\"
```

### Copy alias files to config directory  

```bash
copy-item -Recurse -Verbose express-cli "$HOME\.config\alias\"
```

### Import aliases into PowerShell  

Add the following line to your PowerShell profile  

```bash
. "$HOME\.config\alias\express-cli\windows\index.ps1"
```

### Apply changes  

Reload your profile  

```bash
. $PROFILE
```

### Done  

Your aliases are now active   
You can start using them immediately to speed up your workflow.  

### CLI Commands

To Create a New Project  
Scaffold a new Express project in seconds using one of the following commands:  

```bash
New-ExpressApp project_name
```
