# Scrcpy GUI v3.0

A modern, high-performance, and feature-rich graphical interface for **scrcpy**, built with .NET 10, WPF, and WebView2. This GUI provides a sleek, dark-themed experience for mirroring and controlling Android devices with ease.

<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/06586fc2-b5e3-4edd-bdad-062cd9d49a20" />


## 🚀 Key Features

### 🛠 Core Functionality
*   **Zero-Setup Binary Downloader**: Automatically detects your system architecture (x64 or x86) and downloads/extracts the latest scrcpy binaries directly into the app.
*   **Multiple Mirroring Modes**:
    *   **Standard Mirroring**: Low-latency screen control.
    *   **Camera Mirroring**: Use your phone as a high-end webcam (supports front, back, and external lenses).
    *   **Desktop Mode**: Create an independent virtual workspace on your PC (Android 16+).
    *   **Pure OTG Mode**: Control your phone with your PC mouse/keyboard without a window (USB & Wireless support).

### ⚡ Advanced Camera Support
*   **High-Speed Sensor**: Unlock 120 FPS+ for ultra-smooth monitoring and slow-motion capture.
*   **Sensor Selection**: Manually target specific lenses (Main, Ultra-wide, Macro) using Camera IDs.
*   **H.265 (HEVC) Encoding**: Better performance and quality for high-speed video feeds.

### 📁 File & App Management
*   **Drag-and-Drop APKs**: Instant installation by dropping files onto the GUI.
*   **General File Pushing**: Drag any file to instantly push it to the phone's `Download` folder.
*   **One-Click Screenshots**: Capture the phone screen and save it directly to your PC's Pictures folder.

### 🎨 Personalization & UX
*   **Theme Switcher**: Choose from professionally designed themes:
    *   **Ultraviolet** (Sharp & Modern Purple)
    *   **Astro Blue** (Immersive Space Navy)
    *   **Carbon Stealth** (Minimalist Monochromatic)
    *   **Emerald Stealth** (Professional Green)
    *   **Blood Moon** (High-Contrast Crimson)
*   **Device Nicknames**: Give your devices human-readable names instead of cryptic ADB IDs.
*   **Intelligent Hints**: Modern, multi-line hint boxes for every setting.

## 📥 Download & Use

### For Users (Ready to Run)
If you just want to use the app without touching any code:
1.  Go to the [**Releases**](https://github.com/kil0bit-kb/scrcpy-gui/releases) page.
2.  Download the latest `ScrcpyGUI_v3.0.zip`.
3.  Extract the zip file anywhere on your PC.
4.  Run `ScrcpyGUI.exe`.
5.  Click the **Download** button in the app header to automatically get the required scrcpy binaries.

### For Developers (Build from Source)
1.  Clone the repository:
    ```bash
    git clone https://github.com/kil0bit-kb/scrcpy-gui.git
    ```
2.  Open `ScrcpyGuiDotNet.csproj` in Visual Studio 2022 or newer.
3.  Build and Run.
4.  Click the **Download** button in the header to automatically fetch the scrcpy binaries.

## ⌨️ Shortcuts (Alt + Key)
*   **F**: Full Screen
*   **H**: Home Button
*   **B**: Back Button
*   **S**: Recent Apps
*   **P**: Power Button
*   **R**: Rotate Screen
*   **V**: Paste PC Clipboard to Phone
*   **O**: Turn Device Screen Off

## 🤝 Credits
Created with ❤️ by **KB** (kil0bit).

*   **scrcpy**: [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy)
*   **Icons**: HeroIcons / Lucide

---
*Disclaimer: This project is not affiliated with Genymobile.*
