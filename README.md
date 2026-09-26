# Linux System Monitor

A Bash-based system monitoring project for Linux.

I built this to practice shell scripting and Linux system commands while making something that can actually be used from the terminal.

## Features

- CPU, RAM and disk usage
- Hostname, user and uptime information
- HEALTHY / WARNING / CRITICAL status
- One-time system snapshots
- Live monitoring
- Save and view snapshots
- Snapshot history
- Compare saved snapshots
- Configurable thresholds

## Commands

```bash
./scripts/monitor.sh --help
./scripts/monitor.sh
./scripts/monitor.sh --live 2
./scripts/monitor.sh --save
./scripts/monitor.sh --history
./scripts/monitor.sh --compare
```

## Tech

Bash, Linux, Git

The main goal was to learn Linux and Bash by building a small working tool instead of only practicing individual commands.