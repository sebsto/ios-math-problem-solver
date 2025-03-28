# Math Problem Solver

This iOS application has been entirely generated using Amazon Q Developer CLI. It allows users to take photos of math and physics problems and get step-by-step solutions using Amazon Bedrock and Claude 3.7 Sonnet.

## Features

- Sign in with Apple authentication
- AWS IAM integration using web identity federation
- Camera integration for capturing math problems
- Photo library access for selecting existing images
- Real-time streaming responses from Claude 3.7 Sonnet
- Markdown rendering of mathematical explanations

## Project Structure

```
physics/
├── Assets.xcassets/            # App icons and colors
├── AuthenticationManager.swift # Handles Sign in with Apple and AWS credentials
├── ContentView.swift           # Main UI with camera and response display
├── LoginView.swift             # Sign in with Apple implementation
├── MathSolverApp.swift         # App entry point and state management
├── MathSolverViewModel.swift   # Business logic and Bedrock integration
└── physics.entitlements        # App capabilities configuration
```

## Architecture

The application follows a Model-View-ViewModel (MVVM) architecture:

1. **Views**: 
   - `LoginView`: Handles user authentication with Sign in with Apple
   - `ContentView`: Main interface for capturing/selecting images and displaying solutions

2. **ViewModels**:
   - `MathSolverViewModel`: Manages the business logic for image processing and Bedrock API calls

3. **Models/Managers**:
   - `AuthenticationManager`: Handles authentication state and AWS credential management

## Authentication Flow

1. User authenticates with Sign in with Apple
2. The identity token is used to assume an AWS IAM role using `STSWebIdentityAWSCredentialIdentityResolver`
3. The credential resolver is used to authenticate AWS Bedrock API calls
4. No AWS credentials are stored in the application code

## Getting Started

To run this project:

1. Update the AWS configuration in `AuthenticationManager.swift`:
   - Set your AWS account number
   - Configure your IAM role name
   - Set your preferred AWS region

2. Configure Sign in with Apple in your Apple Developer account

3. Set up an IAM role in your AWS account that trusts the Apple identity provider

## Amazon Q Developer CLI

This project was generated using Amazon Q Developer CLI, a powerful tool that helps developers build applications using natural language instructions.

### Installation

To install Amazon Q Developer CLI:

```bash
# For macOS
brew install aws/tap/q

# For Linux/Windows (via pip)
pip install amazon-q-developer-cli
```

For more information, visit:
- [Amazon Q Developer Documentation](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/what-is-amazon-q-developer.html)
- [Amazon Q Developer CLI GitHub](https://github.com/aws/amazon-q-developer-cli)

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.
