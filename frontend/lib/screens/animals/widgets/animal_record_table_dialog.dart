import 'package:flutter/material.dart';

class AnimalRecordColumnConfig {
  final String key;
  final String label;
  final String hint;
  final double width;

  const AnimalRecordColumnConfig({
    required this.key,
    required this.label,
    required this.hint,
    this.width = 160,
  });
}

const List<AnimalRecordColumnConfig> pedigreeRecordColumns = [
  AnimalRecordColumnConfig(key: 'relation', label: 'Relation', hint: 'Sire, Dam, etc.', width: 140),
  AnimalRecordColumnConfig(key: 'name', label: 'Name', hint: 'Ancestor name', width: 170),
  AnimalRecordColumnConfig(key: 'tagNumber', label: 'Tag Number', hint: 'Tag/registry ID', width: 150),
  AnimalRecordColumnConfig(key: 'breed', label: 'Breed', hint: 'Breed', width: 160),
  AnimalRecordColumnConfig(key: 'notes', label: 'Notes', hint: 'Extra details', width: 210),
];

const List<AnimalRecordColumnConfig> medicalHistoryRecordColumns = [
  AnimalRecordColumnConfig(key: 'date', label: 'Date', hint: 'YYYY-MM-DD', width: 130),
  AnimalRecordColumnConfig(key: 'condition', label: 'Condition', hint: 'Illness / reason', width: 170),
  AnimalRecordColumnConfig(key: 'treatment', label: 'Treatment', hint: 'Drug / procedure', width: 180),
  AnimalRecordColumnConfig(key: 'veterinarian', label: 'Veterinarian', hint: 'Vet name', width: 170),
  AnimalRecordColumnConfig(key: 'notes', label: 'Notes', hint: 'Outcome / remarks', width: 210),
];

List<Map<String, String>> parseAnimalRecordRows({
  required dynamic raw,
  required List<AnimalRecordColumnConfig> columns,
}) {
  if (raw is! List) {
    return const <Map<String, String>>[];
  }

  final allowedKeys = columns.map((column) => column.key).toSet();
  final rows = <Map<String, String>>[];

  for (final item in raw) {
    if (item is! Map) {
      continue;
    }

    final row = <String, String>{};
    for (final entry in item.entries) {
      final key = entry.key.toString();
      if (!allowedKeys.contains(key)) {
        continue;
      }

      final textValue = (entry.value ?? '').toString().trim();
      if (textValue.isNotEmpty) {
        row[key] = textValue;
      }
    }

    if (row.isNotEmpty) {
      rows.add(row);
    }
  }

  return rows;
}

Future<List<Map<String, String>>?> showAnimalRecordTableDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String addRowLabel,
  required List<AnimalRecordColumnConfig> columns,
  required List<Map<String, String>> initialRows,
}) {
  return showDialog<List<Map<String, String>>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _AnimalRecordTableDialog(
        title: title,
        subtitle: subtitle,
        addRowLabel: addRowLabel,
        columns: columns,
        initialRows: initialRows,
      );
    },
  );
}

class _AnimalRecordTableDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String addRowLabel;
  final List<AnimalRecordColumnConfig> columns;
  final List<Map<String, String>> initialRows;

  const _AnimalRecordTableDialog({
    required this.title,
    required this.subtitle,
    required this.addRowLabel,
    required this.columns,
    required this.initialRows,
  });

  @override
  State<_AnimalRecordTableDialog> createState() => _AnimalRecordTableDialogState();
}

class _AnimalRecordTableDialogState extends State<_AnimalRecordTableDialog> {
  final List<_DialogRow> _rows = <_DialogRow>[];
  int _rowCounter = 0;

  @override
  void initState() {
    super.initState();

    final seedRows = widget.initialRows.isEmpty
        ? <Map<String, String>>[const <String, String>{}]
        : widget.initialRows;

    for (final row in seedRows) {
      _rows.add(_newRow(seed: row));
    }
  }

  _DialogRow _newRow({Map<String, String>? seed}) {
    final values = <String, String>{};
    for (final column in widget.columns) {
      values[column.key] = (seed?[column.key] ?? '').trim();
    }

    final row = _DialogRow(
      id: 'row-${DateTime.now().microsecondsSinceEpoch}-${_rowCounter++}',
      values: values,
    );
    return row;
  }

  void _addRow() {
    setState(() {
      _rows.add(_newRow());
    });
  }

  void _removeRow(String rowId) {
    setState(() {
      if (_rows.length == 1) {
        _rows.first.values.updateAll((_, __) => '');
        return;
      }
      _rows.removeWhere((row) => row.id == rowId);
    });
  }

  List<Map<String, String>> _cleanedRows() {
    return _rows
        .map((row) {
          final cleaned = <String, String>{};
          for (final column in widget.columns) {
            final value = (row.values[column.key] ?? '').trim();
            if (value.isNotEmpty) {
              cleaned[column.key] = value;
            }
          }
          return cleaned;
        })
        .where((row) => row.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final tableWidth = widget.columns.fold<double>(56, (sum, column) => sum + column.width);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1120,
          maxHeight: media.size.height * 0.86,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.68)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(widget.addRowLabel),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableWidth),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                          ),
                          columns: [
                            ...widget.columns
                                .map((column) => DataColumn(label: Text(column.label))),
                            const DataColumn(label: Text('Remove')),
                          ],
                          rows: _rows.map((row) {
                            return DataRow(
                              cells: [
                                ...widget.columns.map((column) {
                                  return DataCell(
                                    SizedBox(
                                      width: column.width,
                                      child: TextFormField(
                                        key: ValueKey('${row.id}-${column.key}'),
                                        initialValue: row.values[column.key] ?? '',
                                        onChanged: (value) {
                                          row.values[column.key] = value;
                                        },
                                        decoration: InputDecoration(
                                          hintText: column.hint,
                                          isDense: true,
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                DataCell(
                                  IconButton(
                                    tooltip: 'Delete row',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeRow(row.id),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _cleanedRows()),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save table'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogRow {
  final String id;
  final Map<String, String> values;

  _DialogRow({required this.id, required this.values});
}
