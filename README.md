# Gladden

Gladden is a multi-provider local AI desktop agent built with Flutter. It's designed for privacy, performance, and extensibility. Talk to GPT-4, Gemini Pro, and other models using your own API keys.

## Features
- **Multi-provider Support**: OpenAI and Google Gemini (extensible architecture).
- **Local Storage**: Chat history and API keys are stored locally (keys encrypted with Secure Storage).
- **Cost Estimation**: Real-time token usage and cost tracking based on local pricing tables.
- **Streaming UI**: Responsive chat interface with Markdown support and syntax highlighting.
- **100% Privacy**: No data leaves your machine except to the AI providers you configure.

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (macOS, Windows, or Linux)
- [ObjectBox](https://objectbox.io/flutter-databases/) dependencies (included in pubspec)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/rivendev-app/gladden-desktop-agent-app.git
   ```
2. Navigate to the project directory:
   ```bash
   cd gladden-desktop-agent-app
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate local database code (ObjectBox):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
5. Run the application:
   ```bash
   flutter run -d macos # or windows / linux
   ```

## Project Architecture
The project follows a modular, clean architecture:
- `lib/core`: Base interfaces, cost estimator, and common models.
- `lib/infrastructure`: Implementation of storage services and AI provider adapters.
- `lib/presentation`: UI screens, widgets, and BLoC state management.

## Roadmap
- [ ] Support for local models (Ollama/Llama.cpp).
- [ ] Export chat history to PDF/Markdown.
- [ ] Image generation support.
- [ ] Plugin system for custom tools.

## License
MIT
