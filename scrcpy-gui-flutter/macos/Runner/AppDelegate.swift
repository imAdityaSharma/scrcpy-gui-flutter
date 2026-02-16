import Cocoa
import FlutterMacOS

import SystemExtensions

import SystemExtensions

@main
class AppDelegate: FlutterAppDelegate { //, OSSystemExtensionRequestDelegate {
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        // SYSTEM EXTENSION DISCOVERY:
        // Uncomment the following lines only if you have a paid Apple Developer Account.
        // Personal Teams do not support System Extensions.
        
        /*
        let request = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: "com.imAdityaSharma.scrcpy-gui.ScrcpyCameraExtension", queue: .main)
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
        */
        
        super.applicationDidFinishLaunching(notification)
    }

    /*
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionReplacementAction {
        return .replace
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        print("System Extension ACTIVATED")
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        print("System Extension FAILED: \(error.localizedDescription)")
    }
    */

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
