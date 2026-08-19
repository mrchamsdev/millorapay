import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../repository/unit_repository.dart';
import '../../../widgets/gold_dialogs.dart';

class AddUnitsModal extends StatefulWidget {
  final Unit? unit;
  const AddUnitsModal({super.key, this.unit});

  @override
  State<AddUnitsModal> createState() => _AddUnitsModalState();
}

class _AddUnitsModalState extends State<AddUnitsModal> {
  final _nameController = TextEditingController();
  final _repository = UnitRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.unit != null) {
      _nameController.text = widget.unit!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    String? error;
    if (widget.unit != null && widget.unit!.id != null) {
      error = await _repository.updateUnit(widget.unit!.id!, Unit(name: name));
    } else {
      error = await _repository.createUnit(Unit(name: name));
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.pop(context, true);
      } else {
        GoldDialogs.showSnackBar(
          context,
          widget.unit != null ? 'Failed to update unit' : 'Failed to create unit',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.unit != null ? 'Edit Unit' : 'Add Unit',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF000000)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Unit name',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF121212),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F2F5), width: 1.0)),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF727271),
                ),
                decoration: const InputDecoration(
                  filled: false,
                  hintText: 'Enter here',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF727271),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002E6E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SUBMIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
