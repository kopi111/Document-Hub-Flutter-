import 'package:shared_preferences/shared_preferences.dart';

enum DocumentViewMode { list, grid }

enum DocumentSortOrder { nameAsc, nameDesc, dateNewest, dateOldest }

class DocumentListPreferences {
  static const _viewModeKey = 'document_list_view_mode_v1';
  static const _sortOrderKey = 'document_list_sort_order_v1';

  static const DocumentViewMode defaultViewMode = DocumentViewMode.list;
  static const DocumentSortOrder defaultSortOrder = DocumentSortOrder.nameAsc;

  Future<DocumentViewMode> readViewMode() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_viewModeKey);
    return _decodeViewMode(stored);
  }

  Future<void> writeViewMode(DocumentViewMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_viewModeKey, mode.name);
  }

  Future<DocumentSortOrder> readSortOrder() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_sortOrderKey);
    return _decodeSortOrder(stored);
  }

  Future<void> writeSortOrder(DocumentSortOrder order) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sortOrderKey, order.name);
  }

  DocumentViewMode _decodeViewMode(String? stored) {
    for (final mode in DocumentViewMode.values) {
      if (mode.name == stored) return mode;
    }
    return defaultViewMode;
  }

  DocumentSortOrder _decodeSortOrder(String? stored) {
    for (final order in DocumentSortOrder.values) {
      if (order.name == stored) return order;
    }
    return defaultSortOrder;
  }
}
