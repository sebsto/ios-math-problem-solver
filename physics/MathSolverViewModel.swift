import Foundation
import UIKit
@preconcurrency import AWSBedrockRuntime
@preconcurrency import AWSClientRuntime
import AWSSDKIdentity
import SmithyIdentity

class MathSolverViewModel: ObservableObject {
    @Published var streamedResponse = ""
    @Published var isLoading = false
    
    private var bedrockClient: BedrockRuntimeClient?
    private let modelId = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"
    
    // Reference to the authentication manager
    private weak var authManager: AuthenticationManager?

    init(authManager: AuthenticationManager? = nil) {
        self.authManager = authManager
        setupBedrockClient()
    }
    
    func setAuthManager(_ authManager: AuthenticationManager) {
        self.authManager = authManager
        setupBedrockClient()
    }
    
    func updateCredentials() {
        setupBedrockClient()
    }
    
    private func setupBedrockClient() {
        do {
            let config = try BedrockRuntimeClient.BedrockRuntimeClientConfiguration(
                region: "us-east-1"
            )
            
            // Use identity resolver from AuthenticationManager if available
            if let authManager = authManager, let identityResolver = authManager.identityResolver {
                config.awsCredentialIdentityResolver = identityResolver
                print("Using web identity credential resolver for Bedrock client")
                bedrockClient = BedrockRuntimeClient(config: config)
            } else {
                print("No credential resolver available. User must sign in first.")
                bedrockClient = nil
            }
        } catch {
            print("Error initializing Bedrock client: \(error)")
            bedrockClient = nil
        }
    }
    
    func analyzeImage(_ image: UIImage) {
        guard let bedrockClient = bedrockClient else {
            print("Bedrock client not initialized. Please sign in first.")
            DispatchQueue.main.async {
                self.isLoading = false
                self.streamedResponse = "Error: Authentication required. Please sign in to use this feature."
            }
            return
        }
        
        isLoading = true
        streamedResponse = ""
        
        // Resize image to ensure it's under 5MB when base64 encoded
        let resizedImage = resizeImageIfNeeded(image)
        
        // Start with high quality and progressively reduce until under limit
        var compressionQuality: CGFloat = 0.9
        var imageData: Data?
        var base64Size: Int = 0
        
        repeat {
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
            if let data = imageData {
                // Calculate base64 size (approximately 4/3 of original size)
                base64Size = Int(Double(data.count) * 1.37)
                
                // If still too large, reduce quality and try again
                if base64Size > 5 * 1024 * 1024 { // 5MB
                    compressionQuality -= 0.1
                    print("Image too large (\(ByteCountFormatter.string(fromByteCount: Int64(base64Size), countStyle: .file))), reducing quality to \(compressionQuality)")
                }
            }
        } while base64Size > 5 * 1024 * 1024 && compressionQuality > 0.1
        
        guard let finalImageData = imageData else {
            print("Failed to convert image to data")
            isLoading = false
            return
        }
        
        let base64Size2 = Int(Double(finalImageData.count) * 1.37)
        print("Final image size: \(ByteCountFormatter.string(fromByteCount: Int64(finalImageData.count), countStyle: .file)), estimated base64 size: \(ByteCountFormatter.string(fromByteCount: Int64(base64Size2), countStyle: .file))")
        
        let base64Image = finalImageData.base64EncodedString()
        
        // Create the system prompt
        let systemPrompt = """
        You are a math and physics tutor. Your task is to:
        1. Read and understand the math or physics problem in the image
        2. Provide a clear, step-by-step solution to the problem
        3. Briefly explain any relevant concepts used in solving the problem
        4. Be precise and accurate in your calculations
        5. Use mathematical notation when appropriate
        
        Format your response with clear section headings and numbered steps.
        """

        // Create the request body
        let requestBody: [String: Any] = [
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "temperature": 0.0,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Please solve this math or physics problem. Show all steps and explain the concepts involved."
                        ]
                    ]
                ]
            ]
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: requestBody)
        
        // Create the request
        let input = InvokeModelWithResponseStreamInput(
            body: jsonData,
            contentType: "application/json",
            modelId: modelId
        )
        
        // Make the streaming request
        Task {
            do {
                let output = try await bedrockClient.invokeModelWithResponseStream(input: input)
                
                // Process the streaming response
                for try await chunk in output.body! {
                    if case let .chunk(chunkData) = chunk,
                       let json = try? JSONSerialization.jsonObject(with: chunkData.bytes!) as? [String: Any],
                       let type = json["type"] as? String {
                        
                        if type == "message_delta" {
                            if let delta = json["delta"] as? [String: Any],
                               let content = delta["content"] as? [[String: Any]],
                               let firstContent = content.first,
                               let contentType = firstContent["type"] as? String,
                               contentType == "text",
                               let text = firstContent["text"] as? String {
                                
                                DispatchQueue.main.async {
                                    print("Received message_delta text chunk: \(text.prefix(20))...")
                                    self.streamedResponse += text
                                    print("Current response length: \(self.streamedResponse.count)")
                                }
                            }
                        } else if type == "content_block_delta" {
                            if let delta = json["delta"] as? [String: Any],
                               let text = delta["text"] as? String {
                                
                                DispatchQueue.main.async {
                                    print("Received content_block_delta text chunk: \(text.prefix(20))...")
                                    self.streamedResponse += text
                                    print("Current response length: \(self.streamedResponse.count)")
                                }
                            }
                        }
                    }
                }
                
                print(self.streamedResponse)
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Streaming completed. Final response length: \(self.streamedResponse.count)")
                }
            } catch {
                print("Error in streaming response: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.streamedResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 2048 // Max dimension in pixels
        let scale = image.scale
        let originalSize = image.size
        
        // Calculate scale factor to reduce image size
        let scaleFactor = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
        
        // If image is already smaller than maxDimension, return original
        if scaleFactor >= 1 {
            return image
        }
        
        // Calculate new size
        let newWidth = originalSize.width * scaleFactor
        let newHeight = originalSize.height * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        // Create new image
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        print("Resized image from \(Int(originalSize.width))x\(Int(originalSize.height)) to \(Int(newWidth))x\(Int(newHeight))")
        return resizedImage ?? image
    }
}
