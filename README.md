# Sage: Clinical-Grade Voice Biomarker Analysis Platform

[![iOS](https://img.shields.io/badge/platform-iOS-lightgrey)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/language-Swift%205.5+-orange)](https://swift.org)
[![Architecture](https://img.shields.io/badge/architecture-MVVM%20+%20Domain%20Driven-blue)](https://microsoft.github.io/code-with-engineering-playbook/)
[![Test Coverage](https://img.shields.io/badge/test%20coverage-95%25+-green)](https://codecov.io)

## Overview

Sage is a pioneering voice-based health monitoring platform designed to support women's health research and clinical applications in hormonal disorders. By leveraging clinical-grade speech analysis algorithms and privacy-first infrastructure, Sage transforms smartphone-recorded voice samples into research-quality biomarker data.

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/PoisonIvory/sage.git
   cd sage
   ```

2. **Open in Xcode**
   ```bash
   open Sage.xcodeproj
   ```

3. **Build and run**
   ```bash
   xcodebuild -scheme Sage -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

## Documentation

📚 **All documentation is organized in the [Docs/](./Docs/) directory:**

- **[📋 Project Overview](./Docs/README.md)** - Main project overview and setup guide
- **[🏗️ System Architecture](./Docs/ARCHITECTURE.md)** - High-level architecture and design patterns
- **[🚀 Onboarding Flow](./Docs/ONBOARDING_ARCHITECTURE.md)** - Detailed user journey analysis
- **[📊 Data Pipeline](./Docs/DATA_PIPELINE.md)** - Voice analysis and processing architecture

## Key Features

- **Clinical-Grade Voice Analysis** - Research-quality biomarker extraction
- **Privacy-First Design** - HIPAA-compliant data handling
- **Women's Health Focus** - Specialized for hormonal disorder research
- **Real-Time Processing** - Local and cloud hybrid analysis
- **Comprehensive Testing** - 95%+ test coverage with clinical validation

## Contributing

Please read our [Contributing Guidelines](./Docs/README.md#development--deployment) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*For detailed technical documentation, architecture decisions, and development guidelines, please refer to the [Docs/](./Docs/) directory.* 