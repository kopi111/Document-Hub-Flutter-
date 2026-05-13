import '../models/document.dart';
import '../models/document_cache_state.dart';

abstract class DocumentCacheRepository {
  DocumentCacheState stateFor(PolicyDocument document);
  void recordOpened(PolicyDocument document);
}

class InMemoryDemoDocumentCache implements DocumentCacheRepository {
  static const _cacheTtl = Duration(days: 7);
  static const _expiringWindow = Duration(hours: 24);

  final Map<String, DocumentCacheState> _overrides = {};
  final DateTime Function() _clock;

  InMemoryDemoDocumentCache({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  @override
  DocumentCacheState stateFor(PolicyDocument document) {
    final override = _overrides[document.name];
    if (override != null) return override;
    return _seedStateFor(document);
  }

  @override
  void recordOpened(PolicyDocument document) {
    _overrides[document.name] = DocumentCacheState.cached(_clock());
  }

  DocumentCacheState _seedStateFor(PolicyDocument document) {
    final slot = _slotFor(document.name);
    final now = _clock();
    switch (slot) {
      case 0:
      case 1:
        return DocumentCacheState.cached(now.subtract(const Duration(days: 2)));
      case 2:
        return DocumentCacheState.expiring(
          now.subtract(_cacheTtl - _expiringWindow + const Duration(hours: 1)),
        );
      case 3:
        return DocumentCacheState.updated(now.subtract(const Duration(days: 3)));
      case 4:
        return DocumentCacheState.expired(now.subtract(_cacheTtl + const Duration(hours: 6)));
      default:
        return DocumentCacheState.live;
    }
  }

  int _slotFor(String name) {
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return hash % 10;
  }
}
