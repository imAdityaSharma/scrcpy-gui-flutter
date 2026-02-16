import Foundation
import CoreMediaIO
import os.log

class ExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
    private(set) var provider: CMIOExtensionProvider?
    private let clientQueue: DispatchQueue?
    private var deviceSource: ExtensionDeviceSource?
    
    init(clientQueue: DispatchQueue?) {
        self.clientQueue = clientQueue
        super.init()
    }
    
    func connect(to client: CMIOExtensionClient) throws {
        os_log("ExtensionProviderSource: Connected to client")
    }
    
    func disconnect(from client: CMIOExtensionClient) {
        os_log("ExtensionProviderSource: Disconnected from client")
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.providerManufacturer]
    }
    
    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = "Scrcpy GUI"
        }
        return providerProperties
    }
    
    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
        // Handle writable properties if any
    }
    
    func start() throws {
        guard let provider = provider else { return }
        
        let deviceSource = ExtensionDeviceSource(localizedName: "Scrcpy Camera")
        self.deviceSource = deviceSource
        
        // Create the device with a fixed UUID so checking privacy permissions works consistently
        let deviceID = UUID(uuidString: "77C1D173-6161-4559-8664-583B972E9D97")! // Fixed UUID for persistence
        let device = CMIOExtensionDevice(localizedName: "Scrcpy Camera", deviceID: deviceID, legacyDeviceID: nil, source: deviceSource)
        
        try provider.addDevice(device)
    }
}
