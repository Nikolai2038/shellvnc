# Shell VNC

**EN** | [RU](README_RU.md)

## 1. Description

Shell-scripts to setup remote graphical connection to a Linux machine.

## 2. Installation

```bash
./shellvnc.sh install <server|client|both>
```

## 3. Connect

```bash
./shellvnc.sh connect <host[:port=22]> [user] [password]
```

Example:

```bash
./shellvnc.sh connect arch.local:22 nikolai 3333
```
