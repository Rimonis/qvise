import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log error in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      
      // Call custom error handler if provided
      widget.onError?.call(details);
      
      // Update state to show error UI
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
    };
  }

  void _resetError() {
    setState(() {
      _errorDetails = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      // Show custom error widget if provided, otherwise use default
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_errorDetails!);
      }
      
      return _buildDefaultErrorWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget() {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode 
                    ? _errorDetails!.exception.toString()
                    : 'An unexpected error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _resetError,
                  child: const Text('Try Again'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error Details'),
                          content: SingleChildScrollView(
                            child: Text(
                              _errorDetails!.stack.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Show Stack Trace'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget to catch async errors in a specific subtree
class AsyncErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;
  final void Function(Object error, StackTrace? stack)? onError;

  const AsyncErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<AsyncErrorBoundary> createState() => _AsyncErrorBoundaryState();
}

class _AsyncErrorBoundaryState extends State<AsyncErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  void _handleError(Object error, StackTrace? stack) {
    // Log error in debug mode
    if (kDebugMode) {
      print('AsyncErrorBoundary caught error: $error');
      print(stack);
    }
    
    // Call custom error handler if provided
    widget.onError?.call(error, stack);
    
    // Update state to show error UI
    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = stack;
      });
    }
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Show custom error widget if provided, otherwise use default
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      
      return Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Oops!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDebugMode 
                      ? _error.toString()
                      : 'Something unexpected happened',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _resetError,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Wrap child in error zone
    return ErrorBoundaryZone(
      onError: _handleError,
      child: widget.child,
    );
  }
}

// Helper widget to create an error zone
class ErrorBoundaryZone extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace? stack) onError;

  const ErrorBoundaryZone({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      onError(details.exception, details.stack);
      return const SizedBox.shrink();
    };
    
    return child;
  }
}