; Inno Setup Script for Scrcpy GUI v3.0
#define MyAppName "Scrcpy GUI"
#define MyAppVersion "3.0"
#define MyAppPublisher "KB (kil0bit)"
#define MyAppURL "https://github.com/kil0bit-kb/scrcpy-gui"
#define MyAppExeName "ScrcpyGUI.exe"

[Setup]
AppId={{8B7C2A1E-D3C9-4182-8CDA-B9481C40B789}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\{#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=ScrcpyGUI_v3.0_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=icon.ico
ArchitecturesInstallIn64BitMode=x64 arm64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The installer will pick the correct binary based on the user's PC architecture
Source: "Releases\win-x64\{#MyAppExeName}"; DestDir: "{app}"; Check: Is64BitInstallMode and not IsArm64; Flags: ignoreversion
Source: "Releases\win-x86\{#MyAppExeName}"; DestDir: "{app}"; Check: not Is64BitInstallMode; Flags: ignoreversion
Source: "Releases\win-arm64\{#MyAppExeName}"; DestDir: "{app}"; Check: IsArm64; Flags: ignoreversion
Source: "index.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function IsProcessorFeaturePresent(Feature: Integer): Boolean;
external 'IsProcessorFeaturePresent@kernel32.dll stdcall';

function IsArm64: Boolean;
begin
  Result := IsProcessorFeaturePresent(34);
end;
