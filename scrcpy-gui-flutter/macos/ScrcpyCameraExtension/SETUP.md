# Scrcpy Camera Extension Setup

To enable the native system camera (which doesn't require OBS), you need to manually add the Camera Extension target to the project in Xcode.

## 1. Open Xcode
Open the `macos` folder of this project in Xcode:
`open macos/Runner.xcworkspace`

## 2. Add New Target
1. Select the **Runner** project in the Project Navigator (top left).
2. Click the **+** button at the bottom of the Targets list.
3. Search for **"Camera Extension"**.
4. Set the name to **ScrcpyCameraExtension** (capitalization matters).
5. Ensure the language is **Swift**.
6. Click **Finish**.

## 3. Link Source Files
Xcode will create a new folder named `ScrcpyCameraExtension` with some template files.
1. **Delete** that new folder (Move to Trash).
2. **Drag** the existing `macos/ScrcpyCameraExtension` folder from Finder into the Xcode sidebar.
3. In the dialog that appears:
   - **UNCHECK** "Copy items if needed".
   - **CHECK** the **ScrcpyCameraExtension** target at the bottom.
   - Click **Finish**.

## 4. Signing & Entitlements
1. Select the `ScrcpyCameraExtension` target.
2. Go to **Signing & Capabilities**.
3. Select your **Development Team**.
4. Ensure the **Bundle Identifier** is something like `com.yourname.scrcpy-gui.ScrcpyCameraExtension`.
5. Verify the entitlements match the `ScrcpyCameraExtension.entitlements` file.

## 5. Build & Install
1. Build the main **Runner** target.
2. Once the app launches, click **"Native System Camera"** in the Virtual Webcam view.
3. macOS will prompt you to **"Allow System Extension"**. Open System Settings -> Privacy & Security and click **Allow**.

---
**Note**: You must have an Apple Developer account (free or paid) to sign system extensions on macOS.
