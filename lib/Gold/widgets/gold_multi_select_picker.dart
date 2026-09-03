import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GoldMultiSelectPicker {
  /// Displays a bottom sheet for selecting multiple items of type [T].
  static void show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required List<T> selectedItems,
    required String Function(T) itemTitleBuilder,
    String Function(T)? itemSubtitleBuilder,
    bool Function(T, T)? areItemsEqual,
    required void Function(List<T>) onSelectionChanged,
  }) {
    // Local copy of selections so we can manipulate it before passing it back
    List<T> localSelected = List.from(selectedItems);

    bool _isSelected(T item) {
      if (areItemsEqual != null) {
        return localSelected.any((e) => areItemsEqual(e, item));
      }
      return localSelected.contains(item);
    }

    void _toggle(T item, StateSetter setModalState) {
      setModalState(() {
        if (_isSelected(item)) {
          if (areItemsEqual != null) {
            localSelected.removeWhere((e) => areItemsEqual(e, item));
          } else {
            localSelected.remove(item);
          }
        } else {
          localSelected.add(item);
        }
      });
      onSelectionChanged(localSelected);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = _isSelected(item);
                          final subtitle = itemSubtitleBuilder?.call(item);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(
                              itemTitleBuilder(item),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: subtitle != null && subtitle.isNotEmpty
                                ? Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : null,
                            trailing: SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: Colors.cyan,
                                side: const BorderSide(color: Colors.cyan),
                                onChanged: (_) => _toggle(item, setModalState),
                              ),
                            ),
                            onTap: () => _toggle(item, setModalState),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
