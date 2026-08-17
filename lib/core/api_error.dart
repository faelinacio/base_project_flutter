import 'package:dio/dio.dart';

/// Extracts the human-readable `message` field from a backend [ApiErrorResponse] body, falling
/// back to [fallback] when [error] isn't a [DioException] with that shape.
///
/// Mirrors `extractErrorMessage` from `src/lib/apiClient.ts`.
String extractErrorMessage(
  Object error, {
  String fallback = 'Ocorreu um erro inesperado',
}) {
  final data = _responseData(error);
  final message = data?['message'];
  return message is String && message.isNotEmpty ? message : fallback;
}

/// Extracts the `fieldErrors` map from a backend validation error body, if present.
///
/// Mirrors `extractFieldErrors` from `src/lib/apiClient.ts`.
Map<String, String> extractFieldErrors(Object error) {
  final fieldErrors = _responseData(error)?['fieldErrors'];
  if (fieldErrors is Map) {
    return fieldErrors.map(
      (key, value) => MapEntry(key as String, value as String),
    );
  }
  return const {};
}

/// The HTTP status code of the failed response, if [error] is a [DioException] with one.
int? extractStatusCode(Object error) =>
    error is DioException ? error.response?.statusCode : null;

Map<String, dynamic>? _responseData(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
  }
  return null;
}
