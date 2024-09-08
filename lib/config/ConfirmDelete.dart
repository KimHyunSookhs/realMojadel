// ConfirmDelete.dart
import 'package:flutter/material.dart';

typedef DeleteCallback = Future<void> Function();

class ConfirmDelete extends StatelessWidget {
  final String title;
  final String content;
  final DeleteCallback onDelete;

  const ConfirmDelete({
    Key? key,
    required this.title,
    required this.content,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          child: Text('취소'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('삭제'),
          onPressed: () async {
            Navigator.of(context).pop();
            await onDelete();
          },
        ),
      ],
    );
  }
}
