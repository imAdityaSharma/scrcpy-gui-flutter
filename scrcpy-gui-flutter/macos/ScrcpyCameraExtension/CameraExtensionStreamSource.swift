import Foundation
import CoreMediaIO
import CoreImage
import Network

@available(macOS 12.3, *)
class CameraExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
    let stream: CMIOExtensionStream
    private var _isStreaming = false
    
    // TCP Server for receiving frames
    private var listener: NWListener?
    private var connection: NWConnection?
    private let port: NWEndpoint.Port = 49152 // Dynamic port if needed, but fixed for now
    
    // Video Format
    private let width = 1920
    private let height = 1080
    private let frameRate = 30.0
    
    init(localizedName: String, streamID: UUID) {
        let format = CMIOExtensionStreamFormat(
            formatDescription: try! CMVideoFormatDescription(imageBuffer: nil, codecType: kCMVideoCodecType_h264, width: Int32(width), height: Int32(height)),
            frameDuration: CMTime(value: 1, timescale: Int32(frameRate)),
            maxFrameDuration: CMTime(value: 1, timescale: Int32(frameRate)),
            minFrameDuration: CMTime(value: 1, timescale: Int32(frameRate)),
            validFrameDurations: nil
        )
        
        self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .source, clockType: .hostTime, source: nil)
        super.init()
        self.stream.source = self
        
        do {
            try self.stream.addFormat(format)
            self.stream.activeFormatIndex = 0
        } catch {
            print("Failed to add format: \(error)")
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.streamActiveFormatIndex, .streamFrameDuration]
    }
    
    func streamProperties(for properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = 0
        }
        if properties.contains(.streamFrameDuration) {
            streamProperties.frameDuration = CMTime(value: 1, timescale: Int32(frameRate))
        }
        return streamProperties
    }
    
    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if let index = streamProperties.activeFormatIndex {
            self.stream.activeFormatIndex = index
        }
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        return true
    }
    
    func startStream() throws {
        self._isStreaming = true
        startTCPServer()
    }
    
    func stopStream() throws {
        self._isStreaming = false
        stopTCPServer()
    }
    
    // MARK: - TCP Server Logic
    
    private func startTCPServer() {
        do {
            listener = try NWListener(using: .tcp, on: port)
            listener?.stateUpdateHandler = { state in
                print("Listener state: \(state)")
            }
            listener?.newConnectionHandler = { [weak self] newConnection in
                print("New connection received")
                self?.handleConnection(newConnection)
            }
            listener?.start(queue: .global())
        } catch {
            print("Failed to start listener: \(error)")
        }
    }
    
    private func stopTCPServer() {
        listener?.cancel()
        listener = nil
        connection?.cancel()
        connection = nil
    }
    
    private var buffer = Data()
    
    private func handleConnection(_ connection: NWConnection) {
        self.connection?.cancel() // Only allow one connection at a time
        self.connection = connection
        connection.start(queue: .global())
        receiveData(on: connection)
    }
    
    private func receiveData(on connection: NWConnection) {
        // Read header (frame size) - 4 bytes
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] content, context, isComplete, error in
            guard let self = self, let content = content, content.count == 4 else {
                return
            }
            
            let frameSize = content.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
            
            // Read frame body
            connection.receive(minimumIncompleteLength: Int(frameSize), maximumLength: Int(frameSize)) { content, context, isComplete, error in
                if let content = content, content.count == Int(frameSize) {
                    self.processFrameData(content)
                }
                // Continue receiving
                self.receiveData(on: connection)
            }
        }
    }
    
    private func processFrameData(_ data: Data) {
        guard _isStreaming else { return }
        
        // This data expects to be raw CMSampleBuffer bytes or encoded H264 frame.
        // For simplicity/performance, assume we receive encoded CMSampleBuffer data blob or raw pixels.
        // Or if we used ScreenCaptureKit, we can send CMSampleBuffers directly.
        
        // However, deserializing CMSampleBuffer across IPC is hard.
        // Easier approach: Send raw pixel buffer (CVPixelBuffer) data. 
        // 1920 * 1080 * 4 bytes is ~8MB per frame. Uncompressed. Doable locally?
        
        // For low latency, sending encoded H264 NALUs and decoding here would be best.
        // BUT: Decoding H264 inside the camera extension is efficient.
        
        // Let's assume input is a raw CVPixelBuffer wrapped in Data for V1.
        // Actually, ScreenCaptureKit output is CMSampleBuffer.
        
        // To keep this "Simple", let's reconstruct a CVPixelBuffer from data.
        
        let width = self.width
        let height = self.height
        
        data.withUnsafeBytes { bufferPointer in
            guard let baseAddress = bufferPointer.baseAddress else { return }
            
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreateWithBytes(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_32BGRA,
                UnsafeMutableRawPointer(mutating: baseAddress),
                width * 4,
                nil,
                nil,
                nil,
                &pixelBuffer
            )
            
            if status == kCVReturnSuccess, let pixelBuffer = pixelBuffer {
                // Get current time
                 let now = CMClockGetTime(CMClockGetHostTimeClock())
                
                var formatDescription: CMFormatDescription?
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
                
                var sampleBuffer: CMSampleBuffer?
                var timingInfo = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: now, decodeTimeStamp: CMTime.invalid)
                
                CMSampleBufferCreateForImageBuffer(
                    allocator: kCFAllocatorDefault,
                    imageBuffer: pixelBuffer,
                    dataReady: true,
                    makeDataReadyCallback: nil,
                    refcon: nil,
                    formatDescription: formatDescription!,
                    sampleTiming: &timingInfo,
                    sampleBufferOut: &sampleBuffer
                )
                
                if let sampleBuffer = sampleBuffer {
                    self.stream.send(sampleBuffer, discontinuity: [], hostTimeInNanoseconds: UInt64(now.seconds * 1_000_000_000))
                }
            }
        }
    }
}
