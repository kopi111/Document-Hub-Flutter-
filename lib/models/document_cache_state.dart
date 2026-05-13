enum DocumentCacheStatus { live, cached, expiring, expired, updated }

class DocumentCacheState {
  final DocumentCacheStatus status;
  final DateTime? cachedAt;

  const DocumentCacheState._({required this.status, this.cachedAt});

  static const DocumentCacheState live = DocumentCacheState._(
    status: DocumentCacheStatus.live,
  );

  factory DocumentCacheState.cached(DateTime cachedAt) =>
      DocumentCacheState._(status: DocumentCacheStatus.cached, cachedAt: cachedAt);

  factory DocumentCacheState.expiring(DateTime cachedAt) =>
      DocumentCacheState._(status: DocumentCacheStatus.expiring, cachedAt: cachedAt);

  factory DocumentCacheState.expired(DateTime cachedAt) =>
      DocumentCacheState._(status: DocumentCacheStatus.expired, cachedAt: cachedAt);

  factory DocumentCacheState.updated(DateTime cachedAt) =>
      DocumentCacheState._(status: DocumentCacheStatus.updated, cachedAt: cachedAt);

  bool get isOpenable => status != DocumentCacheStatus.expired;
}
