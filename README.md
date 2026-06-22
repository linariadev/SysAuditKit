# SysAuditKit

A modular Linux system audit tool packaged as a `.deb` package.  
Note: All scripts and system output messages are written in French.

## Features

- **init** — Create a system user and configure workspace
- **report** — Generate a system audit report (disk, memory, processes)
- **search** — Search files by extension, size, or keyword
- **monitor** — Monitor and manage running processes

## Requirements

- Ubuntu 22.04+
- Bash 4+
- Root access (`sudo`)

## Installation

**1. Clone the repository**
```bash
git clone https://github.com/linariadev/SysAuditKit.git
cd SysAuditKit
```

**2. Build the package**
```bash
dpkg-deb --build sysauditkit_1.0.0_all
```

**3. Install**
```bash
sudo dpkg -i sysauditkit_1.0.0_all.deb
```

**4. Verify**
```bash
dpkg -l | grep sysauditkit
```

## Usage

```bash
sudo sysauditkit init
sudo sysauditkit report
sysauditkit search -d /var/log -e .log -k "error"
sysauditkit monitor -t 5
sysauditkit monitor -u lina
```

## Project Structure

```
sysauditkit_1.0.0_all/
├── DEBIAN/
│   └── control
├── usr/
│   ├── bin/
│   │   └── sysauditkit        # Main dispatcher
│   └── lib/
│       └── sysauditkit/
│           ├── init.sh
│           ├── report.sh
│           ├── search.sh
│           └── monitor.sh
└── etc/
    └── sysauditkit/
        └── owner.conf         # Generated after init
```

## Author

Lina Ben Yassi — EMSI Tanger, 3IIR

Note: This is an academic project (January 2026).
