import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

/// Utility class to handle network errors with user-friendly messages
class NetworkErrorHandler {
  /// Get a user-friendly error message and suggestion for network errors
  static String getErrorMessage(dynamic error) {
    // Handle common network exceptions
    if (error is SocketException) {
      if (error.message.contains('Failed host lookup') ||
          error.message.contains('no address associated with hostname')) {
        return 'Unable to connect to the server (DNS resolution failed).\n\n'
            'Please check your internet connection and try:\n'
            '• Turning off airplane mode\n'
            '• Connecting to a different WiFi network\n'
            '• Switching between WiFi and mobile data\n'
            '• Restarting your device';
      } else if (error.message.contains('Connection refused')) {
        return 'The server refused the connection.\n\n'
            'Please try again later.';
      } else if (error.message.contains('Connection timed out')) {
        return 'Connection timed out.\n\n'
            'Please check your internet speed and try again.';
      }

      return 'Network error: ${error.message}\n\n'
          'Please check your internet connection and try again.';
    } else if (error is HttpException) {
      return 'Unable to complete the request: ${error.message}';
    } else if (error is TimeoutException) {
      return 'Connection timed out.\n\n'
          'Please check your internet speed and try again later.';
    } else if (error is FormatException) {
      return 'Invalid data format received from the server.\n\n'
          'Please try again later.';
    }

    // Generic error message
    return 'An error occurred while connecting to the server.\n\n'
        'Please check your internet connection and try again.';
  }

  /// Show a user-friendly error dialog with suggestions for network issues
  static void showErrorDialog(BuildContext context, dynamic error) {
    String message = getErrorMessage(error);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Error'),
          content: SingleChildScrollView(child: Text(message)),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                // You would typically trigger a retry here
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Helper to determine if error is a network/connectivity issue
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
        error is HttpException ||
        error is TimeoutException ||
        (error is Exception && error.toString().contains('Failed host lookup'));
  }
}
