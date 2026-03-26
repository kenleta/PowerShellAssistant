# 🚀 Universal PowerShell Smart Assistant (v1.1)

A lightweight, intelligent script to supercharge your PowerShell experience. This assistant automates module installation and fixes common path errors in real-time.

---

## 🌟 Key Features / 核心功能

### 1. 📂 CD Smart-Fix (Path Auto-Quoting)
Stop worrying about quotes! If you copy a path containing spaces, just type \cd \ and paste it. The assistant catches the error and fixes it automatically.
* **Input:** \cd C:\Program Files\Common Files\
* **Result:** Successfully jumps to the directory without manual quotes.

### 2. 📦 Auto-Module Installer & Retry
When you type a command that isn't installed (e.g., \Connect-AzAccount\), the assistant will:
1. Search the **PowerShell Gallery**.
2. Identify the required module.
3. Offer to install and **Auto-Retry** your original command.

### 3. 🛡️ Safety & Management
* **Auto-Backup**: Creates a \.bak\ of your original profile during the first installation.
* **Anti-Duplicate**: Smart tags prevent multiple injections if the script is run more than once.
* **Local Uninstall**: No need to run the web script again to remove it.

---

## 🚀 One-Liner Installation / 一键部署

Copy and paste this command into your PowerShell terminal:

```powershell
iex (irm bit.ly/4bApAGU)
```

---

## 🏮 中文快速说明

这是一个为您解决 PowerShell 日常痛点的智能辅助脚本：

- **极速部署**: 使用 \iex (irm bit.ly/4bApAGU)\ 一键完成配置。
- **空格路径修正**: \cd\ 带空格的路径时自动修正，无需手动加引号。
- **缺失命令自动安装**: 自动搜索缺失模块，询问安装并在安装后**自动重试**原始命令。
- **一键卸载**: 在终端输入 \Uninstall-Assistant\ 即可完全清理并恢复备份。
- **环境安全**: 首次安装自动备份旧配置文件，且具备防重复写入逻辑。

---

## 🛠️ Usage & Uninstallation

| Action | Command |
| :--- | :--- |
| **Install** | `iex (irm bit.ly/4bApAGU)` |
| **Uninstall** | `Uninstall-Assistant` |

---

## ⚖️ License

Copyright 2026 Ken Liu

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
