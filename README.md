# Win10+ Setup Disk & Win2Go (IT Groceries Shop MOD)

![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows)
![Language](https://img.shields.io/badge/Language-PowerShell-5391FE?logo=powershell)
![License](https://img.shields.io/badge/License-CommunityWare-green)

A modernized PowerShell script for creating **Windows Setup Disks** and **Windows To Go** drives.
This project is a modified version (fork) of the popular MDL/GitHub script, enhanced with **Real-time USB Auto-Scan** and improved Launcher logic by **IT Groceries Shop**.

<img width="496" height="598" alt="win10setupdisk" src="https://github.com/user-attachments/assets/f71d7fef-ea81-462e-b729-6ef5d5b378a4" />

## 🚀 Quick Start

Run PowerShell as **Administrator** and paste this command:

```powershell
iex(irm bit.ly/win10setupdisk)
```
> **Note:** Requires an active internet connection to download the latest script configuration.

## ✨ Features

### ⚡ IT Groceries Shop Modifications (MOD)
* **Real-time USB Auto-Scan:** No need to restart the script! Plug in your USB drive, and it appears instantly (1-second polling interval).
* **Smart Launcher:** Can launch without a USB drive attached initially.
* **Web-Based Execution:** Integrated with a cloud-based launcher for easy access via shortlink.
* **UI/UX Improvements:** Custom branding, layout adjustments, and status indicators.

### 🛠 Core Functionality (From Original Project)
* **Windows Setup Disk:** Create bootable USBs for Windows 10/11 installation.
* **Windows To Go:** Install a portable Windows OS directly onto a USB drive.
* **Bypass TPM/Secure Boot:** Option to patch Windows 11 requirements automatically.
* **AutoUnattend Support:** Inject custom `AutoUnattend.xml` for automated installation.
* **Legacy/UEFI Support:** Supports both partition schemes.

## 📖 How to Use

1. **Prepare:** Have your Windows ISO file ready.
2. **Run:** Open PowerShell (Admin) and run the command above.
3. **Select ISO:** Click **"Windows ISO"** and choose your `.iso` file (or extracted folder).
4. **Target USB:** Plug in your USB drive. It will auto-detect and appear in the list.
5. **Choose Mode:**
    * *Windows Setup Disk:* For installing Windows on other PCs.
    * *Windows To Go:* For running Windows directly from the USB.
6. **Create:** Click **"Create Disk"** and wait for the process to finish.

## 🏆 Credits & Acknowledgments

This tool is built upon the hard work of the **MyDigitalLife (MDL)** community and open-source contributors.

* **Original Project:** [Win10-Setup-Disk](https://github.com/abdullah-erturk/Win10-Setup-Disk-)
* **Original Author:** `abdullah-erturk`
* **Core Contributors:** @rpo, @freddie-o, @BAU, @abbodi1406, @mephistooo2, @mustafa-gotr (bensuslu11)
* **Reference:** [TNCTR](https://www.tnctr.com/)

**Modded & Maintained by:**
* **Developer:** Jay (IT Groceries Shop)
* **YouTube:** [IT Groceries Shop](https://www.youtube.com/@ITGroceries)
* **Blog:** [ITG Blog](https://itgroceries.blogspot.com/)

## ⚠️ Disclaimer

This software is provided "as is", without warranty of any kind. The authors and modifiers are not responsible for any data loss or hardware damage. **Always backup your USB drive data before use**, as the process involves formatting.
