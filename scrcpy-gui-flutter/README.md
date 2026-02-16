# Scrcpy GUI (Flutter Port)

A modern, cross-platform graphical user interface for [scrcpy](https://github.com/Genymobile/scrcpy), built with Flutter.

![Screenshot](screenshot.png)

## Features

- **Device Management**: Automatic USB detection, wireless pairing (Android 11+), and connection history.
- **Session Modes**:
  - **Screen Mirror**: Low-latency control with mouse and keyboard.
  - **Camera Mirror**: Use your phone as a high-quality webcam.
    - *New:* Per-camera rotation and FPS settings.
  - **Desktop Mode**: Experience a desktop-like environment (if supported).
- **Advanced Controls**:
  - Adjust Bitrate, Resolution, and FPS on the fly.
  - Support for H.264, H.265 (HEVC), and AV1 codecs.
  - Screen recording with custom path selection.
- **Smart Features**:
  - Drag & Drop APK installation.
  - Theming engine with 5 distinct styles.
  - Keyboard shortcuts for common actions.
  - Real-time log output for debugging.

## Getting Started

### Prerequisites

You must have `adb` and `scrcpy` installed and available in your system PATH.

- **macOS**: `brew install scrcpy android-platform-tools`
- **Windows**: Download `scrcpy` release and add to PATH.
- **Linux**: `apt install scrcpy adb`

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/scrcpy-gui-flutter.git
   cd scrcpy-gui-flutter
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run -d macos  # or windows/linux
   ```

## Credits

This project is a Flutter port based on the original **Scrcpy GUI** by **[kil0bit-kb](https://github.com/kil0bit-kb/scrcpy-gui)**.

Original Project: https://github.com/kil0bit-kb/scrcpy-gui

## License

MIT License. See [LICENSE](LICENSE) for details.
