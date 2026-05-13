class ApiException implements Exception {
  final String message;
  final String? errorCode;
  final String? requestId;

  const ApiException(this.message, {this.errorCode, this.requestId});

  @override
  String toString() {
    final parts = <String>[runtimeType.toString(), ': ', message];
    if (errorCode != null) parts.addAll([' (', errorCode!, ')']);
    if (requestId != null) parts.addAll([' [request_id=', requestId!, ']']);
    return parts.join();
  }
}

class BadRequestException extends ApiException {
  const BadRequestException(super.message, {super.errorCode, super.requestId});
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.errorCode, super.requestId});
}

class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.errorCode, super.requestId});
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.errorCode, super.requestId});
}

class RateLimitedException extends ApiException {
  final Duration retryAfter;

  const RateLimitedException(
    super.message,
    this.retryAfter, {
    super.errorCode,
    super.requestId,
  });
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.errorCode, super.requestId});
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class ApiDeprecatedException extends ApiException {
  const ApiDeprecatedException(super.message);
}
