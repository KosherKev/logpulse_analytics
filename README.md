# LogPulse Analytics

A mobile analytics dashboard for centralized API logging service built with Flutter.

## Features

- 📊 Real-time dashboard with system health metrics
- ⚠️ Error tracking with smart grouping
- 🔍 Advanced log browsing and filtering
- 📈 Service performance analytics
- 🔔 Push notifications for critical errors
- 🌙 Dark mode support

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd logpulse_analytics

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── utils/
│   └── errors/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── pages/
    ├── widgets/
    └── providers/
```

## Configuration

Update your API configuration in Settings or create a `.env` file:

```env
API_BASE_URL=https://your-logging-service.run.app
API_KEY=your-api-key
```

## Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## License

MIT License - See LICENSE file for details

## Author

Techknowslogic
