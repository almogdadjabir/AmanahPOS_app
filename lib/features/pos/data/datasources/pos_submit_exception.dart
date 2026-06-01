enum PosSubmitFailureType {
  network,
  timeout,
  serverUnavailable,
  business,
  unauthorized,
  unknown,
}

class PosSubmitException implements Exception {
  final String message;
  final PosSubmitFailureType type;

  const PosSubmitException({
    required this.message,
    required this.type,
  });

  bool get canQueueOffline {
    return type == PosSubmitFailureType.network ||
        type == PosSubmitFailureType.timeout ||
        type == PosSubmitFailureType.serverUnavailable;
  }

  @override
  String toString() => message;
}