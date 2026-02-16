import Foundation
import CoreMediaIO
import os.log

class ExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {
    private(set) var device: CMIOExtensionDevice!
    private(set) weak var provider: CMIOExtensionProvider?
    private let localizedName: String
    private var streamSource: ExtensionStreamSource?
    
    init(localizedName: String) {
        self.localizedName = localizedName
        super.init()
    }
    
    func connect(to client: CMIOExtensionClient) throws {
        // Handle client connection
    }
    
    func disconnect(from client: CMIOExtensionClient) {
        // Handle client disconnection
    }
    
    func start() {
        guard let device = device else { return }
        
        // 1080p stream
        let streamSource = ExtensionStreamSource(width: 1920, height: 1080)
        self.streamSource = streamSource
        
        let streamID = UUID(uuidString: "2D8E09D3-3D5B-4C2E-9D4C-9D5C5B5D5E5D")!
        let stream = CMIOExtensionStream(localizedName: "Scrcpy Video", streamID: streamID, direction: .source, clockType: .hostTime, source: streamSource)
        
        do {
            try device.addStream(stream)
        } catch {
            os_log("Failed to add stream: %{public}@", error.localizedDescription)
        }
    }
    
    func stop() {
        // No-op
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.deviceModel]
    }
    
    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
        if properties.contains(.deviceModel) {
            deviceProperties.model = "Scrcpy Camera"
        }
        return deviceProperties
    }
    
    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
        // Handle writable properties
    }
    
}
