import Foundation
import CoreMediaIO
import CoreMedia
import os.log
import Network

class ExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
    private(set) var stream: CMIOExtensionStream?
    private var videoDescription: CMVideoFormatDescription?
    private var listener: NWListener?
    private var connection: NWConnection?
    
    private var width: Int32
    private var height: Int32
    
    private(set) var localizedName: String = "Scrcpy Video"
    private(set) var clockType: CMIOExtensionStream.ClockType = .hostTime
    
    init(width: Int32 = 1920, height: Int32 = 1080) {
        self.width = width
        self.height = height
        super.init()
    }
    
    private(set) var activeFormatIndex: Int = 0 {
        didSet {
            if activeFormatIndex >= formats.count {
                activeFormatIndex = 0
            }
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.streamActiveFormatIndex, .streamFrameDuration]
    }
    
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = 0
        }
        if properties.contains(.streamFrameDuration) {
            streamProperties.frameDuration = CMTime(value: 1, timescale: 30)
        }
        
        return streamProperties
    }
    
    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if streamProperties.activeFormatIndex != nil {
            // efficient format change logic here
        }
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        return true // Add real validation if needed
    }
    
    func startStream() throws {
        setupReceiver()
    }
    
    func stopStream() throws {
        listener?.cancel()
        connection?.cancel()
    }
    
    private func createFormatDescription() throws -> CMVideoFormatDescription {
        if let existing = videoDescription { return existing }
        var description: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault, codecType: kCVPixelFormatType_32BGRA, width: width, height: height, extensions: nil, formatDescriptionOut: &description)
        videoDescription = description
        return description!
    }
    
    var formats: [CMIOExtensionStreamFormat] {
        get {
            var formats: [CMIOExtensionStreamFormat] = []
            if let formatDesc = try? createFormatDescription() {
                let format = CMIOExtensionStreamFormat(
                    formatDescription: formatDesc,
                    maxFrameDuration: CMTime(value: 1, timescale: 30),
                    minFrameDuration: CMTime(value: 1, timescale: 60),
                    validFrameDurations: nil
                )
                formats.append(format)
            }
            return formats
        }
    }
    
    func start() throws {
        // start() legacy support not needed for protocol
    }
    
    func stop() throws {
        // stop() legacy support not needed for protocol
    }
    
    private func setupReceiver() {
        // Listen on a port for raw frames (BGRA)
        // Port 5001 arbitrarily chosen
        do {
            listener = try NWListener(using: .tcp, on: 5001)
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            listener?.start(queue: .global())
            os_log("ExtensionStreamSource: Listening for frames on port 5001")
        } catch {
            os_log("ExtensionStreamSource: Failed to start listener: %{public}@", error.localizedDescription)
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        self.connection?.cancel()
        self.connection = connection
        connection.start(queue: .global())
        receiveFrame()
    }
    
    private func receiveFrame() {
        guard let connection = connection else { return }
        
        let frameSize = Int(width * height * 4)
        connection.receive(minimumIncompleteLength: frameSize, maximumLength: frameSize) { [weak self] data, context, isComplete, error in
            if let data = data, data.count == frameSize {
                self?.processFrame(data)
                self?.receiveFrame() // Get next frame
            }
            if let error = error {
                os_log("ExtensionStreamSource: Receive error: %{public}@", error.localizedDescription)
            }
        }
    }
    
    private func processFrame(_ data: Data) {
        guard stream != nil else { return }
        
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)
        data.copyBytes(to: baseAddress!.assumingMemoryBound(to: UInt8.self), count: data.count)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 30), presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()), decodeTimeStamp: .invalid)
        
        guard let formatDesc = try? createFormatDescription() else { return }
        
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescription: formatDesc, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
        
        if let sb = sampleBuffer, let s = stream {
            s.send(sb, discontinuity: [], hostTimeInNanoseconds: UInt64(timingInfo.presentationTimeStamp.seconds * 1_000_000_000))
        }
    }
}
