# 🖥️ Linux System Monitor

A lightweight, customizable **Linux system monitoring tool built with Bash**.

Linux System Monitor provides a terminal-based dashboard for monitoring CPU, RAM, and disk usage, tracking system information, monitoring top processes, generating alerts, saving snapshots, and comparing system performance over time.

---

## 📸 Dashboard

```text
╔════════════════════════════════════════════╗
║          LINUX SYSTEM MONITOR              ║
║             SYSTEM DASHBOARD               ║
║     Snapshot: 2026-08-30 14:23:43 UTC      ║
╚════════════════════════════════════════════╝

┌───────── SYSTEM INFORMATION ────────────────────┐
│ Hostname:     Vishwas
│ Current User: vishwas_sharma
│ Uptime:       up 3 hours, 59 minutes
└─────────────────────────────────────────────────┘

┌───────── RESOURCE USAGE ────────────────────────┐
│ CPU  : [█░░░░░░░░░░░░░░░░░░░] 1.1%   [HEALTHY]
│
│ RAM  : [███░░░░░░░░░░░░░░░░░] 16.7%   [HEALTHY]
│
│ DISK : [█░░░░░░░░░░░░░░░░░░░] 1%   [HEALTHY]
└─────────────────────────────────────────────────┘
```

---

## ✨ Features

### 🖥️ System Information

Displays important information about the current Linux system:

* Hostname
* Current user
* System uptime
* Snapshot timestamp

### 📊 Resource Monitoring

Monitors the major system resources:

* CPU usage
* RAM usage
* Disk usage
* Visual progress bars

### 🟢 Health Status

Automatically classifies resource usage as:

* `HEALTHY`
* `WARNING`
* `CRITICAL`

### 🚨 Resource Alerts

Generates alerts when resource usage crosses configured thresholds.

Example:

```text
┌────────────── ALERTS ──────────────────┐
│ ⚠ WARNING: RAM usage is high: 75.2%
└─────────────────────────────────────────┘
```

### 🔄 Live Monitoring

Continuously refreshes the dashboard directly in the terminal.

```bash
./monitor.sh --live
```

Custom refresh interval:

```bash
./monitor.sh --live 5
```

### 💾 Snapshot System

Save the current system state:

```bash
./monitor.sh --save
```

Snapshots are stored with timestamps:

```text
snapshots/
├── snapshot_2026-08-30_11-44-47.txt
├── snapshot_2026-08-30_12-22-31.txt
└── snapshot_2026-08-30_14-10-28.txt
```

### 📚 Snapshot History

View previously saved snapshots:

```bash
./monitor.sh --history
```

### 👁️ View Snapshots

View the latest snapshot:

```bash
./monitor.sh --view
```

View a specific snapshot:

```bash
./monitor.sh --view snapshot_2026-08-30_14-10-28.txt
```

### 🔀 Snapshot Comparison

Compare the latest two snapshots:

```bash
./monitor.sh --compare
```

Example:

```text
┌──────────── SNAPSHOT COMPARISON ─────────────┐
│             OLD       CURRENT       CHANGE
│ CPU         1.2%       1.1%        ↓ -0.1
│ RAM        16.5%      16.7%        ↑ +0.2
│ DISK        1%         1%          ━ 0.0
└───────────────────────────────────────────────┘
```

### ⚙️ Configurable Thresholds

Monitoring thresholds are stored separately in `config.conf`.

```bash
WARNING_THRESHOLD=70
CRITICAL_THRESHOLD=90
```

This allows monitoring behavior to be changed without modifying the main script.

### 🔢 Exit Codes

The monitor provides standard exit codes for automation:

| Exit Code | Meaning  |
| --------: | -------- |
|       `0` | Healthy  |
|       `1` | Warning  |
|       `2` | Critical |

This allows other scripts or automation tools to use the monitor's result.

### 🆘 Command-Line Help

Display available commands:

```bash
./monitor.sh --help
```

---

## 🛠️ Technologies Used

* **Bash**
* **Linux CLI**
* `top`
* `free`
* `df`
* `ps`
* `awk`
* `grep`
* `sed`
* `bc`
* `date`

---

## 📁 Project Structure

```text
linux-system-monitor/
│
├── monitor.sh
├── config.conf
├── README.md
├── .gitignore
│
├── scripts/
├── logs/
└── snapshots/
```

### Main Components

| File / Directory | Purpose                                       |
| ---------------- | --------------------------------------------- |
| `monitor.sh`     | Main monitoring script                        |
| `config.conf`    | Monitoring configuration                      |
| `snapshots/`     | Stores system snapshots                       |
| `logs/`          | Reserved for monitoring logs                  |
| `scripts/`       | Supporting scripts                            |
| `.gitignore`     | Prevents unnecessary files from being tracked |
| `README.md`      | Project documentation                         |

---

## 🚀 Installation

### 1. Clone the repository

```bash
git clone <YOUR-GITHUB-REPOSITORY-URL>
```

### 2. Enter the project directory

```bash
cd linux-system-monitor
```

### 3. Make the script executable

```bash
chmod +x monitor.sh
```

### 4. Install `bc`

Ubuntu/Debian:

```bash
sudo apt install bc
```

### 5. Run the monitor

```bash
./monitor.sh
```

---

## ▶️ Usage

### Default Dashboard

```bash
./monitor.sh
```

Displays a one-time system snapshot.

### Live Monitoring

```bash
./monitor.sh --live
```

Default refresh interval:

```text
2 seconds
```

Custom interval:

```bash
./monitor.sh --live 5
```

### Save Snapshot

```bash
./monitor.sh --save
```

### Snapshot History

```bash
./monitor.sh --history
```

### View Latest Snapshot

```bash
./monitor.sh --view
```

### View Specific Snapshot

```bash
./monitor.sh --view snapshot_FILENAME.txt
```

### Compare Snapshots

```bash
./monitor.sh --compare
```

### Help

```bash
./monitor.sh --help
```

---

## ⚙️ Configuration

Edit the configuration file:

```bash
nano config.conf
```

Default configuration:

```bash
WARNING_THRESHOLD=70
CRITICAL_THRESHOLD=90
```

For example:

```bash
WARNING_THRESHOLD=60
CRITICAL_THRESHOLD=80
```

With this configuration:

```text
0–59%   → HEALTHY
60–79%  → WARNING
80%+    → CRITICAL
```

---

## 🧠 How It Works

The project combines several standard Linux utilities to collect system information.

```text
                monitor.sh
                    │
        ┌───────────┼───────────┐
        ↓           ↓           ↓
       CPU          RAM        DISK
        │           │           │
       top         free         df
        │           │           │
        └───────────┼───────────┘
                    ↓
             Usage Analysis
                    ↓
          ┌─────────┼─────────┐
          ↓         ↓         ↓
       HEALTHY   WARNING   CRITICAL
                    │
                    ↓
                 Alerts
                    │
                    ↓
              Dashboard
```

Snapshots can then be saved and compared:

```text
Current System
      ↓
   --save
      ↓
  Snapshot
      ↓
History
      ↓
--compare
      ↓
Performance Change
```

---

## 🎯 Learning Outcomes

This project demonstrates practical experience with:

* Bash scripting
* Linux command-line tools
* Shell variables
* Functions
* Conditional statements
* Loops
* Command substitution
* Pipelines
* Text processing
* `awk`
* `grep`
* `sed`
* `bc`
* File handling
* Configuration management
* Process monitoring
* Exit status codes
* Git and GitHub workflow
* Basic Linux system administration

---

## 🔮 Future Improvements

Possible future versions:

* 🌡️ CPU temperature monitoring
* 🌐 Network usage monitoring
* 📈 Historical usage graphs
* 📧 Email notifications
* 🔔 Desktop notifications
* 📄 CSV export
* 🔧 JSON output mode
* 📝 Log rotation
* 🐳 Docker support
* 🌐 Web-based dashboard
* ⏱️ Scheduled monitoring
* 📊 Long-term system statistics

---

## 🧪 Testing

Before using the project, validate the Bash script:

```bash
bash -n monitor.sh
```

Run the dashboard:

```bash
./monitor.sh
```

Test live monitoring:

```bash
./monitor.sh --live 5
```

Test snapshot functionality:

```bash
./monitor.sh --save
./monitor.sh --history
./monitor.sh --view
```

Test comparison:

```bash
./monitor.sh --compare
```

---

## 📌 Project Status

**Status: Portfolio Ready 🚀**

The current version includes the core monitoring, snapshot, comparison, configuration, alert, and CLI functionality.

---

## 👨‍💻 Author

**Vishwas Sharma**

Built as a practical Linux and Bash scripting project to explore system monitoring, automation, command-line tools, and Linux administration concepts.

---

## 📜 License

This project is licensed under the MIT License.
