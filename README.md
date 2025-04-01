# TradeGasy

![TradeGasy](assets/Logo W.png)

TradeGasy is a Flutter-based mobile and web application designed to help Malagasy traders and international users analyze cryptocurrency markets with AI assistance. The app leverages the power of AI language models to provide meaningful market analysis and trading signals.

## Features

- **Real-time Market Data**: View candlestick charts for major cryptocurrency pairs from Binance
- **AI-powered Analysis**: Get professional-grade market analysis using the OpenRouter API (Claude model)
- **Trading Signals**: Receive automated trading signals based on technical indicators
- **Interactive Chat Interface**: Ask specific questions about any trading pair and timeframe
- **Multiple Timeframes**: Analyze market data across various intervals from 1 minute to 5 years
- **Dark/Light Theme**: Switch between themes based on your preference

## Screenshots

<table>
  <tr>
    <td><img src="assets/screenshots/home_screen.png" width="200"/></td>
    <td><img src="assets/screenshots/market_screen.png" width="200"/></td>
    <td><img src="assets/screenshots/signal_detail.png" width="200"/></td>
  </tr>
  <tr>
    <td>Home Screen</td>
    <td>Market Analysis</td>
    <td>Signal Details</td>
  </tr>
</table>

## Getting Started

### Prerequisites

- Flutter 3.7.0 or higher
- Dart SDK 3.0.0 or higher
- An OpenRouter API key (for AI functionality)
- A Binance API key (optional, for enhanced functionality)

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/tradegasy.git
   cd tradegasy
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the root directory with your API keys:
   ```
   BINANCE_API_KEY=your_binance_api_key
   BINANCE_API_SECRET=your_binance_api_secret
   OPENROUTER_API_KEY=your_openrouter_api_key
   ```

4. Run the app
   ```bash
   flutter run
   ```

### Building for Production

#### Android

```bash
flutter build apk --release
```

The APK file will be located at `build/app/outputs/flutter-apk/app-release.apk`

#### Web

```bash
flutter build web --release
```

## Architecture

TradeGasy follows a clean architecture approach with the following structure:

- **lib/models**: Data models for Binance data and trading signals
- **lib/screens**: UI screens for different sections of the app
- **lib/services**: API service classes for Binance and OpenRouter
- **lib/utils**: Utility classes and helpers
- **lib/widgets**: Reusable UI components
- **lib/providers**: State management classes

## Technical Details

- **State Management**: Provider pattern for simple and effective state management
- **Data Persistence**: SharedPreferences with fallback to in-memory storage
- **API Integration**: 
  - Binance API for real-time market data
  - OpenRouter API for AI-powered analysis using Claude models
- **Technical Analysis**: Custom implementation of indicators like RSI, MACD, and EMA

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Binance API](https://binance-docs.github.io/apidocs/)
- [OpenRouter](https://openrouter.ai/)
- [Candlesticks](https://pub.dev/packages/candlesticks) package for chart visualization

## Contact

Project Link: [https://github.com/yourusername/tradegasy](https://github.com/yourusername/tradegasy)

---

Made with ❤️ for Malagasy traders
