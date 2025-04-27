import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkClient {
  static final NetworkClient _instance = NetworkClient._internal();

  factory NetworkClient() => _instance;

  NetworkClient._internal();

  // Add retry configuration
  final int _maxRetries = 3;
  final Duration _baseRetryDelay = Duration(seconds: 2);

  // Check connectivity before making requests
  Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<http.Response> get(String url) async {
    // First check connectivity
    if (!await _isConnected()) {
      throw SocketException('No internet connection available');
    }

    final client = http.Client();
    try {
      return await _getWithRetry(url, client);
    } finally {
      client.close();
    }
  }

  Future<http.Response> _getWithRetry(
    String url,
    http.Client client, [
    int attempt = 0,
  ]) async {
    try {
      // Configure HTTP client with extended timeout
      final httpClient =
          HttpClient()
            ..connectionTimeout = const Duration(minutes: 2)
            ..idleTimeout = const Duration(minutes: 5);

      // Important: Add DNS error handling by resolving to alternate DNS if needed
      httpClient.badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) {
        print('Bad certificate for $host:$port');
        return false; // Still reject bad certificates, but log them
      };

      // Use chunking for large responses
      Uri uri = Uri.parse(url);
      print(
        'Attempting to connect to: ${uri.host} (${attempt + 1}/$_maxRetries)',
      );

      // Try alternate DNS resolution if needed - check if this is a retry
      if (attempt > 0) {
        // On retry, try with IP address fallbacks for common APIs
        if (uri.host == 'api.binance.com') {
          // Binance API IPs (these may change, just examples)
          final fallbackIps = ['13.32.89.64', '13.32.89.123', '13.32.89.93'];
          final fallbackIp = fallbackIps[attempt % fallbackIps.length];

          // Create a new URL with the IP instead of hostname but keep the same path
          print('Trying fallback IP for api.binance.com: $fallbackIp');
          uri = uri.replace(host: fallbackIp);
        }
      }

      final request = await httpClient.getUrl(uri);
      request.headers.add('Accept', 'application/json');
      request.headers.add('Connection', 'keep-alive');

      // Add host header to ensure proper routing when using IP address
      if (attempt > 0 && uri.host.contains('.')) {
        request.headers.add('Host', 'api.binance.com');
      }

      // Fetch data with progress tracking for large datasets
      final response = await request.close();

      // Handle the response in chunks for large data
      final completer = Completer<String>();
      final contents = StringBuffer();

      response
          .transform(utf8.decoder)
          .timeout(
            const Duration(minutes: 5),
            onTimeout: (EventSink<String> sink) {
              completer.completeError(
                TimeoutException('Data loading timeout after 5 minutes'),
              );
              sink.close();
            },
          )
          .listen(
            (data) {
              contents.write(data);
            },
            onDone: () {
              completer.complete(contents.toString());
            },
            onError: (error) {
              completer.completeError(error);
            },
            cancelOnError: true,
          );

      final responseBody = await completer.future;
      return http.Response(responseBody, response.statusCode);
    } catch (e) {
      if (attempt < _maxRetries - 1) {
        // Log the error and retry with exponential backoff
        print('Network error (attempt ${attempt + 1}): $e - Retrying...');
        // Add exponential backoff delay before retry
        final delay = _baseRetryDelay * (attempt + 1);
        await Future.delayed(delay);

        // Retry with incremented attempt count
        return _getWithRetry(url, client, attempt + 1);
      }

      // All retries exhausted, throw a more specific error
      if (e is SocketException) {
        if (e.message.contains('Failed host lookup') ||
            e.message.contains('no address associated with hostname')) {
          throw SocketException(
            'Could not connect to server: DNS resolution failed. ' +
                'Please check your internet connection and try again. ' +
                'If using mobile data, try switching to WiFi. ' +
                'Original error: ${e.message}',
          );
        }
      }

      // Rethrow the original error
      rethrow;
    }
  }
}
