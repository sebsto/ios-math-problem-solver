# Math & Physics Problem Solver

An iOS application that uses Amazon Bedrock with Claude to solve math and physics problems from photos.

## Features

- Take photos of math or physics problems using the device camera
- Send images to Amazon Bedrock using Claude Anthropic model
- Get step-by-step solutions with explanations of relevant concepts
- View results in real-time with streaming API

## Requirements

- iOS 15.0+
- Xcode 14.0+
- AWS account with Bedrock access
- AWS credentials configured on your device

## Setup

1. Clone the repository
2. Configure AWS credentials with Bedrock access
3. Open the project in Xcode
4. Build and run on a physical iOS device (camera functionality requires a physical device)

## How It Works

1. The app captures an image using the device camera
2. The image is converted to base64 and sent to Amazon Bedrock
3. Claude analyzes the problem and provides a step-by-step solution
4. Results are displayed progressively as they stream in

## Architecture

- **SwiftUI**: For the user interface
- **AWS SDK for Swift**: For communication with Amazon Bedrock
- **Claude 3 Sonnet**: For problem analysis and solution generation

## System Prompt

The app uses a carefully crafted system prompt to guide Claude:

```
You are a math and physics tutor. Your task is to:
1. Read and understand the math or physics problem in the image
2. Provide a clear, step-by-step solution to the problem
3. Briefly explain any relevant concepts used in solving the problem
4. Be precise and accurate in your calculations
5. Use mathematical notation when appropriate

Format your response with clear section headings and numbered steps.
```

## Privacy

The app requires camera permissions to function. All image processing is done through secure AWS services.
