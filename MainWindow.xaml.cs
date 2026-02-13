using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using Microsoft.Web.WebView2.Core;

namespace ScrcpyGuiDotNet
{
    public partial class MainWindow : Window
    {
        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

        private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;

        public MainWindow()
        {
            InitializeComponent();
            SourceInitialized += MainWindow_SourceInitialized;
            InitializeAsync();
        }

        private void MainWindow_SourceInitialized(object? sender, EventArgs e)
        {
            var helper = new WindowInteropHelper(this);
            int useDarkMode = 1;
            DwmSetWindowAttribute(helper.Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, ref useDarkMode, sizeof(int));
        }

        async void InitializeAsync()
        {
            try
            {
                var userDataFolder = Path.Combine(System.IO.Path.GetTempPath(), "ScrcpyGui_WebView2");
                var env = await CoreWebView2Environment.CreateAsync(userDataFolder: userDataFolder);
                await webView.EnsureCoreWebView2Async(env);

                webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
                webView.CoreWebView2.Settings.IsZoomControlEnabled = false;
                
                // Allow file access from local pages (optional, but good for local assets)
                // webView.CoreWebView2.SetVirtualHostNameToFolderMapping("app.assets", "assets", CoreWebView2HostResourceAccessKind.Allow);

                var bridge = new AppBridge(webView.CoreWebView2, this);
                webView.CoreWebView2.AddHostObjectToScript("bridge", bridge);

                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string indexPath = Path.Combine(baseDir, "index.html");
                
                if (File.Exists(indexPath))
                {
                    webView.CoreWebView2.Navigate("file:///" + indexPath.Replace("\\", "/"));
                }
                else
                {
                    MessageBox.Show("Critical Error: index.html not found in " + baseDir);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error initializing WebView2: " + ex.Message);
            }
        }
    }
}