using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using Microsoft.Web.WebView2.Core;
using Microsoft.Win32;

namespace ScrcpyGuiDotNet
{
    [ComVisible(true)]
    public class AppBridge
    {
        private CoreWebView2 _webview;
        private Window _window;
        private Dictionary<string, Process> _scrcpyProcesses = new Dictionary<string, Process>();
        private string? _lastUsedPath = null;
        private static readonly HttpClient _httpClient = new HttpClient();

        public AppBridge(CoreWebView2 webview, Window window)
        {
            _webview = webview;
            _window = window;
            if (!_httpClient.DefaultRequestHeaders.Contains("User-Agent"))
            {
                _httpClient.DefaultRequestHeaders.TryAddWithoutValidation("User-Agent", "ScrcpyGuiDotNet-Downloader");
            }
        }

        public async void DownloadScrcpy()
        {
            try
            {
                // Detect architecture
                string archSearch = Environment.Is64BitOperatingSystem ? "win64" : "win32";
                SendLog($"Detecting system architecture: {(Environment.Is64BitOperatingSystem ? "64-bit" : "32-bit")}");
                
                SendStatus("downloading", true, $"Fetching latest {archSearch} release...");
                
                var response = await _httpClient.GetStringAsync("https://api.github.com/repos/Genymobile/scrcpy/releases/latest");
                using var doc = JsonDocument.Parse(response);
                var root = doc.RootElement;
                
                string? downloadUrl = null;
                string? fileNameOnGithub = null;

                foreach (var asset in root.GetProperty("assets").EnumerateArray())
                {
                    string name = asset.GetProperty("name").GetString() ?? "";
                    if (name.Contains(archSearch) && name.EndsWith(".zip"))
                    {
                        downloadUrl = asset.GetProperty("browser_download_url").GetString();
                        fileNameOnGithub = name;
                        break;
                    }
                }

                if (string.IsNullOrEmpty(downloadUrl))
                {
                    SendStatus("downloading", false, $"Could not find {archSearch} binary on GitHub.");
                    return;
                }

                SendLog($"Found asset: {fileNameOnGithub}");


                string zipPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scrcpy_temp.zip");
                string extractPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scrcpy-bin");

                using (var downloadResponse = await _httpClient.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead))
                {
                    downloadResponse.EnsureSuccessStatusCode();
                    var totalBytes = downloadResponse.Content.Headers.ContentLength ?? -1L;
                    var canReportProgress = totalBytes != -1;
                    
                    SendLog($"Starting download: {totalBytes / 1024 / 1024} MB");

                    using (var contentStream = await downloadResponse.Content.ReadAsStreamAsync())
                    using (var fileStream = new FileStream(zipPath, FileMode.Create, FileAccess.Write, FileShare.None, 65536, true))
                    {
                        var buffer = new byte[65536];
                        var totalRead = 0L;
                        var isMoreToRead = true;

                        do
                        {
                            var read = await contentStream.ReadAsync(buffer, 0, buffer.Length);
                            if (read == 0)
                            {
                                isMoreToRead = false;
                            }
                            else
                            {
                                await fileStream.WriteAsync(buffer, 0, read);
                                totalRead += read;

                                if (canReportProgress)
                                {
                                    int progress = (int)((totalRead * 100) / totalBytes);
                                    SendDownloadProgress(progress);
                                }
                            }
                        } while (isMoreToRead);
                    }
                }

                SendLog("Download finished. Starting extraction...");
                SendStatus("downloading", true, "Extracting binaries...");
                if (Directory.Exists(extractPath)) Directory.Delete(extractPath, true);
                
                // Extract to a subfolder, scrcpy zip usually contains a folder named 'scrcpy-win64-vX.X'
                string tempDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "temp_extract");
                if (Directory.Exists(tempDir)) Directory.Delete(tempDir, true);
                ZipFile.ExtractToDirectory(zipPath, tempDir);

                // Move contents from inner folder to scrcpy-bin
                var innerDir = Directory.GetDirectories(tempDir).FirstOrDefault();
                if (innerDir != null)
                {
                    Directory.Move(innerDir, extractPath);
                }
                else
                {
                    Directory.Move(tempDir, extractPath);
                }

                if (Directory.Exists(tempDir)) Directory.Delete(tempDir, true);
                if (File.Exists(zipPath)) File.Delete(zipPath);

                _lastUsedPath = extractPath;
                SendStatus("download-complete", true, extractPath);
            }
            catch (Exception ex)
            {
                SendStatus("downloading", false, "Error: " + ex.Message);
            }
        }

        private void SendDownloadProgress(int percent)
        {
            string json = JsonSerializer.Serialize(new { type = "download-progress", percent });
            _window.Dispatcher.Invoke(() => _webview.PostWebMessageAsJson(json));
        }

        private void SendStatus(string type, bool success, string message)
        {
            string json = JsonSerializer.Serialize(new { type = type, success, message });
            _window.Dispatcher.Invoke(() => _webview.PostWebMessageAsJson(json));
        }

        public string GetDefaultVideoPath()
        {
            return Environment.GetFolderPath(Environment.SpecialFolder.MyVideos);
        }

        private string GetBinaryPath(string binaryName, string? customFolder)
        {
            if (!string.IsNullOrEmpty(customFolder))
            {
                string ext = binaryName.EndsWith(".exe") ? "" : ".exe";
                string fullPath = Path.Combine(customFolder, binaryName + ext);
                if (File.Exists(fullPath))
                {
                    _lastUsedPath = customFolder;
                    return fullPath;
                }
            }
            // Assume in PATH or local directory if not found
            return binaryName;
        }

        public string CheckScrcpy(string? customPath)
        {
            try
            {
                string exePath = GetBinaryPath("scrcpy", customPath);
                var psi = new ProcessStartInfo
                {
                    FileName = exePath,
                    Arguments = "--version",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var p = Process.Start(psi))
                {
                    if (p == null) return JsonSerializer.Serialize(new { found = false, message = "Failed to start scrcpy" });
                    p.WaitForExit();
                    if (p.ExitCode == 0)
                        return JsonSerializer.Serialize(new { found = true, message = "Scrcpy Ready" });
                }
            }
            catch { }
            return JsonSerializer.Serialize(new { found = false, message = "Scrcpy not found" });
        }

        public string AdbShell(string? customPath, string deviceId, string command)
        {
            try
            {
                string adbPath = GetBinaryPath("adb", customPath);
                var psi = new ProcessStartInfo(adbPath, $"-s {deviceId} shell {command}")
                {
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                Process.Start(psi)?.WaitForExit();
                return JsonSerializer.Serialize(new { success = true });
            }
            catch (Exception ex) { return JsonSerializer.Serialize(new { success = false, message = ex.Message }); }
        }

        public string PushFile(string jsonArgs)
        {
            try
            {
                var d = JsonSerializer.Deserialize<Dictionary<string, string?>>(jsonArgs);
                if (d == null) return JsonSerializer.Serialize(new { success = false, message = "Invalid arguments" });

                string device = d.ContainsKey("device") ? (d["device"] ?? "") : "";
                string filePath = d.ContainsKey("filePath") ? (d["filePath"] ?? "") : "";
                string? customPath = d.ContainsKey("customPath") ? d["customPath"] : null;

                string adbPath = GetBinaryPath("adb", customPath);
                // Push to Download folder by default
                string fileName = Path.GetFileName(filePath);
                var psi = new ProcessStartInfo(adbPath, $"-s {device} push \"{filePath}\" /sdcard/Download/")
                {
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                
                using(var p = Process.Start(psi))
                {
                    if (p == null) return JsonSerializer.Serialize(new { success = false, message = "Failed to start ADB" });
                    p.WaitForExit();
                    return JsonSerializer.Serialize(new { success = p.ExitCode == 0, message = p.ExitCode == 0 ? "File pushed to Downloads" : "Transfer failed" });
                }
            }
            catch(Exception ex) { return JsonSerializer.Serialize(new { success = false, message = ex.Message }); }
        }

        public string TakeScreenshot(string? customPath, string deviceId)
        {
            try
            {
                string adbPath = GetBinaryPath("adb", customPath);
                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                string pcPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), $"scrcpy_shot_{timestamp}.png");
                
                // Capture to temp location on phone
                var capPsi = new ProcessStartInfo(adbPath, $"-s {deviceId} shell screencap -p /sdcard/screen.png") { UseShellExecute = false, CreateNoWindow = true };
                Process.Start(capPsi)?.WaitForExit();

                // Pull to PC
                var pullPsi = new ProcessStartInfo(adbPath, $"-s {deviceId} pull /sdcard/screen.png \"{pcPath}\"") { UseShellExecute = false, CreateNoWindow = true };
                Process.Start(pullPsi)?.WaitForExit();

                return JsonSerializer.Serialize(new { success = true, path = pcPath });
            }
            catch (Exception ex) { return JsonSerializer.Serialize(new { success = false, message = ex.Message }); }
        }

        public string GetDevices(string? customPath)
        {
            try
            {
                string adbPath = GetBinaryPath("adb", customPath);
                var psi = new ProcessStartInfo
                {
                    FileName = adbPath,
                    Arguments = "devices",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var p = Process.Start(psi))
                {
                    if (p == null) return JsonSerializer.Serialize(new { error = true, message = "Failed to start ADB" });
                    string output = p.StandardOutput.ReadToEnd();
                    p.WaitForExit();

                    var lines = output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                    var devices = lines.Skip(1)
                        .Where(l => l.Contains("\tdevice"))
                        .Select(l => l.Split('\t')[0].Trim())
                        .ToList();

                    return JsonSerializer.Serialize(new { error = false, devices });
                }
            }
            catch (Exception ex)
            {
                return JsonSerializer.Serialize(new { error = true, message = ex.Message });
            }
        }

        public string KillAdb(string customPath)
        {
            try
            {
                foreach (var kvp in _scrcpyProcesses)
                {
                    try { kvp.Value.Kill(); } catch { }
                }
                _scrcpyProcesses.Clear();

                string adbPath = GetBinaryPath("adb", customPath ?? _lastUsedPath);
                
                var psi = new ProcessStartInfo(adbPath, "kill-server") { UseShellExecute = false, CreateNoWindow = true };
                Process.Start(psi)?.WaitForExit();

                // Force kill
                Process.Start(new ProcessStartInfo("taskkill", "/F /IM adb.exe /T") { UseShellExecute = false, CreateNoWindow = true })?.WaitForExit();

                return JsonSerializer.Serialize(new { success = true, message = "ADB Stack Terminated" });
            }
            catch (Exception ex)
            {
                return JsonSerializer.Serialize(new { success = false, message = ex.Message });
            }
        }

        public string AdbConnect(string jsonArgs)
        {
            try
            {
                var args = JsonSerializer.Deserialize<Dictionary<string, string?>>(jsonArgs);
                if (args == null) return JsonSerializer.Serialize(new { success = false, message = "Invalid arguments" });

                string ip = args.ContainsKey("ip") ? (args["ip"] ?? "") : "";
                string? customPath = args.ContainsKey("customPath") ? args["customPath"] : null;

                string adbPath = GetBinaryPath("adb", customPath);
                var psi = new ProcessStartInfo(adbPath, $"connect {ip}")
                {
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var p = Process.Start(psi))
                {
                    if (p == null) return JsonSerializer.Serialize(new { success = false, message = "Failed to start ADB" });
                    string outText = p.StandardOutput.ReadToEnd();
                    string errText = p.StandardError.ReadToEnd();
                    p.WaitForExit();

                    if (p.ExitCode != 0 || outText.Contains("cannot connect"))
                        return JsonSerializer.Serialize(new { success = false, message = outText + errText });
                    
                    return JsonSerializer.Serialize(new { success = true, message = outText.Trim() });
                }
            }
            catch (Exception ex)
            {
                return JsonSerializer.Serialize(new { success = false, message = ex.Message });
            }
        }

        public string AdbPair(string jsonArgs)
        {
            try
            {
                var args = JsonSerializer.Deserialize<Dictionary<string, string?>>(jsonArgs);
                if (args == null) return JsonSerializer.Serialize(new { success = false, message = "Invalid arguments" });

                string ip = args.ContainsKey("ip") ? (args["ip"] ?? "") : "";
                string code = args.ContainsKey("code") ? (args["code"] ?? "") : "";
                string? customPath = args.ContainsKey("customPath") ? args["customPath"] : null;

                string adbPath = GetBinaryPath("adb", customPath);
                var psi = new ProcessStartInfo(adbPath, $"pair {ip} {code}")
                {
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var p = Process.Start(psi))
                {
                    if (p == null) return JsonSerializer.Serialize(new { success = false, message = "Failed to start ADB" });
                    string outText = p.StandardOutput.ReadToEnd();
                    p.WaitForExit();
                    return JsonSerializer.Serialize(new { success = true, message = outText.Trim() });
                }
            }
            catch (Exception ex)
            {
                return JsonSerializer.Serialize(new { success = false, message = ex.Message });
            }
        }

        public string InstallApk(string jsonArgs)
        {
             try
            {
                var d = JsonSerializer.Deserialize<Dictionary<string, string?>>(jsonArgs);
                if (d == null) return JsonSerializer.Serialize(new { success = false, message = "Invalid arguments" });

                string device = d.ContainsKey("device") ? (d["device"] ?? "") : "";
                string filePath = d.ContainsKey("filePath") ? (d["filePath"] ?? "") : "";
                string? customPath = d.ContainsKey("customPath") ? d["customPath"] : null;

                string adbPath = GetBinaryPath("adb", customPath);
                var psi = new ProcessStartInfo(adbPath, $"-s {device} install \"{filePath}\"")
                {
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                
                using(var p = Process.Start(psi))
                {
                    if (p == null) return JsonSerializer.Serialize(new { success = false, message = "Failed to start ADB" });
                    string outText = p.StandardOutput.ReadToEnd();
                    string errText = p.StandardError.ReadToEnd();
                    p.WaitForExit();
                     if (p.ExitCode != 0)
                        return JsonSerializer.Serialize(new { success = false, message = errText });
                    else
                        return JsonSerializer.Serialize(new { success = true, message = outText.Trim() });
                }
            }
            catch(Exception ex) { return JsonSerializer.Serialize(new { success = false, message = ex.Message }); }
        }

        public string? SelectFolder()
        {
            string? selectedPath = null;
            _window.Dispatcher.Invoke(() =>
            {
                var dialog = new OpenFolderDialog();
                if (dialog.ShowDialog() == true)
                {
                    selectedPath = dialog.FolderName;
                }
            });
            return selectedPath;
        }

        public string GetCameraInfo(string? customPath, string deviceId)
        {
            try
            {
                string scrcpyPath = GetBinaryPath("scrcpy", customPath);
                var psi = new ProcessStartInfo
                {
                    FileName = scrcpyPath,
                    Arguments = $"-s {deviceId} --list-cameras",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var p = Process.Start(psi))
                {
                    if (p == null) return JsonSerializer.Serialize(new { success = false, message = "Failed to start scrcpy" });
                    string output = p.StandardOutput.ReadToEnd();
                    string error = p.StandardError.ReadToEnd();
                    p.WaitForExit();
                    return JsonSerializer.Serialize(new { success = true, output = output + error });
                }
            }
            catch (Exception ex) { return JsonSerializer.Serialize(new { success = false, message = ex.Message }); }
        }

        public string GetCameraSizes(string? customPath, string deviceId, string cameraFacing)
        {
            try
            {
                string scrcpyPath = GetBinaryPath("scrcpy", customPath);
                var psi = new ProcessStartInfo
                {
                    FileName = scrcpyPath,
                    Arguments = $"-s {deviceId} --video-source=camera --camera-facing={cameraFacing} --list-camera-sizes",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var p = Process.Start(psi))
                {
                    if (p == null) return JsonSerializer.Serialize(new { success = false, message = "Failed to start scrcpy" });
                    string output = p.StandardOutput.ReadToEnd();
                    string error = p.StandardError.ReadToEnd();
                    p.WaitForExit();
                    return JsonSerializer.Serialize(new { success = true, output = output + error });
                }
            }
            catch (Exception ex) { return JsonSerializer.Serialize(new { success = false, message = ex.Message }); }
        }
        
        public void OpenPath(string path)
        {
            try 
            { 
                if (string.IsNullOrEmpty(path)) return;
                Process.Start(new ProcessStartInfo(path.Replace("\"", "")) { UseShellExecute = true }); 
            } 
            catch (Exception ex) 
            {
                SendLog("Failed to open path: " + ex.Message);
            }
        }

        public void RunScrcpy(string jsonConfig)
        {
            try
            {
                var doc = JsonDocument.Parse(jsonConfig);
                var root = doc.RootElement;
                
                string deviceId = root.GetProperty("device").GetString() ?? "";
                if (string.IsNullOrEmpty(deviceId) || _scrcpyProcesses.ContainsKey(deviceId)) return;

                var args = new List<string>();
                if (!string.IsNullOrEmpty(deviceId)) { args.Add("-s"); args.Add(deviceId); }

                string sessionMode = root.GetProperty("sessionMode").GetString() ?? "mirror";
                string codec = root.TryGetProperty("codec", out var cod) ? (cod.GetString() ?? "h264") : "h264";
                args.Add($"--video-codec={codec}");
                
                bool otgEnabled = root.TryGetProperty("otgEnabled", out var otgE) && otgE.GetBoolean();
                bool otgPure = root.TryGetProperty("otgPure", out var otgP) && otgP.GetBoolean();

                if (sessionMode == "mirror" && otgEnabled && otgPure)
                {
                    // Pure OTG (--otg) only works via physical USB.
                    // For wireless, we emulate it using --no-video and uhid.
                    if (deviceId.Contains(".") || deviceId.Contains(":"))
                    {
                        args.Add("--no-video");
                        args.Add("--no-audio");
                        args.Add("--keyboard=uhid");
                        args.Add("--mouse=uhid");
                    }
                    else
                    {
                        args.Add("--otg");
                    }
                }
                else
                {
                    string bitrate = root.TryGetProperty("bitrate", out var br) ? (br.ToString() ?? "8") : "8";
                    args.Add("-b"); args.Add(bitrate + "M");

                    // Shared Behavior Flags (Apply to all modes)
                    if (root.TryGetProperty("audioEnabled", out var ae) && !ae.GetBoolean()) args.Add("--no-audio");
                    if (root.TryGetProperty("alwaysOnTop", out var aot) && aot.GetBoolean()) args.Add("--always-on-top");
                    if (root.TryGetProperty("fullscreen", out var fs) && fs.GetBoolean()) args.Add("--fullscreen");
                    if (root.TryGetProperty("borderless", out var bl) && bl.GetBoolean()) args.Add("--window-borderless");
                    
                    string rotation = root.TryGetProperty("rotation", out var rot) ? (rot.ToString() ?? "0") : "0";
                    if (rotation != "0") { args.Add("--orientation"); args.Add(rotation); }

                    // Feature-specific flags (Stay Awake & Screen Off)
                    bool canControl = (sessionMode != "camera");
                    if (canControl && root.TryGetProperty("stayAwake", out var sa) && sa.GetBoolean()) args.Add("--stay-awake");
                    if (canControl && root.TryGetProperty("turnOff", out var to) && to.GetBoolean()) 
                    {
                        args.Add("--turn-screen-off");
                        args.Add("--no-power-on");
                    }

                    if (sessionMode == "camera")
                    {
                        args.Add("--video-source=camera");
                        
                        string? camId = root.TryGetProperty("cameraId", out var cid) ? cid.GetString() : null;
                        if (!string.IsNullOrEmpty(camId))
                        {
                            args.Add($"--camera-id={camId}");
                        }
                        else
                        {
                            string facing = root.TryGetProperty("cameraFacing", out var cf) ? (cf.GetString() ?? "back") : "back";
                            args.Add($"--camera-facing={facing}");
                        }

                        string res = root.TryGetProperty("res", out var r) ? (r.ToString() ?? "0") : "0";
                        string ar = root.TryGetProperty("cameraAr", out var car) ? (car.ToString() ?? "0") : "0";
                        
                        // Cannot specify both --camera-size and --camera-ar
                        if (res != "0") 
                        {
                            string camRes = res;
                            if (res == "3840") camRes = "3840x2160";
                            else if (res == "2560") camRes = "2560x1440";
                            else if (res == "1920") camRes = "1920x1080";
                            else if (res == "1280") camRes = "1280x720";
                            args.Add($"--camera-size={camRes}");
                        }
                        else if (ar != "0") 
                        {
                            args.Add($"--camera-ar={ar}");
                        }

                        if (root.TryGetProperty("cameraHighSpeed", out var chs) && chs.GetBoolean()) args.Add("--camera-high-speed");
                        
                        string fps = root.TryGetProperty("fps", out var f) ? (f.ToString() ?? "60") : "60";
                        args.Add($"--camera-fps={fps}");
                    }
                    else if (sessionMode == "desktop")
                    {
                        string w = root.TryGetProperty("vdWidth", out var vdw) ? (vdw.ToString() ?? "1920") : "1920";
                        string h = root.TryGetProperty("vdHeight", out var vdh) ? (vdh.ToString() ?? "1080") : "1080";
                        string dpi = root.TryGetProperty("vdDpi", out var vdd) ? (vdd.ToString() ?? "420") : "420";
                        args.Add($"--new-display={w}x{h}/{dpi}");
                        
                        args.Add("--video-buffer=100");

                        string fps = root.TryGetProperty("fps", out var f) ? (f.ToString() ?? "60") : "60";
                        args.Add("--max-fps"); args.Add(fps);
                    }
                    else
                    {
                        if (otgEnabled) 
                        { 
                            // Updated for scrcpy 3.x
                            args.Add("--keyboard=uhid"); 
                            args.Add("--mouse=uhid"); 
                        }
                        
                        string res = root.TryGetProperty("res", out var r) ? (r.ToString() ?? "0") : "0";
                        if (res != "0") { args.Add("-m"); args.Add(res); }

                        string fps = root.TryGetProperty("fps", out var f) ? (f.ToString() ?? "60") : "60";
                        args.Add("--max-fps"); args.Add(fps);
                    }

                    if (root.TryGetProperty("record", out var rec) && rec.GetBoolean())
                    {
                        string? recPath = root.TryGetProperty("recordPath", out var rp) ? rp.GetString() : GetDefaultVideoPath();
                        if (string.IsNullOrEmpty(recPath)) recPath = GetDefaultVideoPath();
                        string filename = $"scrcpy_{deviceId.Replace(":", "-")}_{DateTime.Now:yyyyMMdd_HHmmss}.mkv";
                        string fullRecPath = Path.Combine(recPath!, filename);
                        args.Add($"--record={fullRecPath}");
                    }
                }

                string? customPath = root.TryGetProperty("scrcpyPath", out var sp) ? sp.GetString() : null;
                string executable = GetBinaryPath("scrcpy", customPath);

                var psi = new ProcessStartInfo
                {
                    FileName = executable,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                foreach (var arg in args)
                {
                    psi.ArgumentList.Add(arg);
                }

                var proc = new Process();
                proc.StartInfo = psi;
                
                proc.OutputDataReceived += (s, e) => { if(e.Data != null) SendLog(e.Data); };
                proc.ErrorDataReceived += (s, e) => { if(e.Data != null) SendLog(e.Data); };
                proc.EnableRaisingEvents = true;
                proc.Exited += (s, e) => {
                    _scrcpyProcesses.Remove(deviceId);
                    SendStatus(deviceId, false);
                };

                proc.Start();
                proc.BeginOutputReadLine();
                proc.BeginErrorReadLine();

                _scrcpyProcesses[deviceId] = proc;
                SendStatus(deviceId, true);
            }
            catch (Exception ex)
            {
                SendLog("Error starting scrcpy: " + ex.Message);
            }
        }

        public void StopScrcpy(string deviceId)
        {
            if (_scrcpyProcesses.TryGetValue(deviceId, out var p))
            {
                try { p.Kill(); } catch { }
            }
        }

        private void SendLog(string msg)
        {
            string json = JsonSerializer.Serialize(new { type = "log", message = msg });
            _window.Dispatcher.Invoke(() => _webview.PostWebMessageAsJson(json));
        }

        private void SendStatus(string device, bool running)
        {
            string json = JsonSerializer.Serialize(new { type = "status", device, running });
             _window.Dispatcher.Invoke(() => _webview.PostWebMessageAsJson(json));
        }
    }
}
