import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class Dialpad extends StatefulWidget {
  final TextEditingController searchController;
  final VoidCallback onFilterContacts;
  final VoidCallback onClose;

  const Dialpad({
    super.key,
    required this.searchController,
    required this.onFilterContacts,
    required this.onClose,
  });

  @override
  State<Dialpad> createState() => _DialpadState();
}

class _DialpadState extends State<Dialpad> {
  String _dialedNumber = '';

  void _onDigitPressed(String digit) {
    setState(() {
      _dialedNumber += digit;
      widget.searchController.text = _dialedNumber;
      widget.onFilterContacts();
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_dialedNumber.isNotEmpty) {
        _dialedNumber = _dialedNumber.substring(0, _dialedNumber.length - 1);
        widget.searchController.text = _dialedNumber;
        widget.onFilterContacts();
      }
    });
  }

  void _onCallPressed() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Initiate Call', style: theme.textTheme.titleLarge),
          content: Text('Calling: $_dialedNumber', style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showContactDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            contact.displayName ?? '',
            style: theme.textTheme.titleLarge,
          ),
          content: Row(
            children: [
              Icon(
                Icons.phone,
                size: 20.0,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  contact.phones.isNotEmpty ? contact.phones.first.number : 'No number',
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: Text(
              _dialedNumber.isEmpty ? 'Enter number' : _dialedNumber,
              style: theme.textTheme.titleLarge?.copyWith(
                color: _dialedNumber.isEmpty
                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 46.0,
            childAspectRatio: 1.6,
            children: [
              _buildDialButton('1', ''),
              _buildDialButton('2', 'ABC'),
              _buildDialButton('3', 'DEF'),
              _buildDialButton('4', 'GHI'),
              _buildDialButton('5', 'JKL'),
              _buildDialButton('6', 'MNO'),
              _buildDialButton('7', 'PQRS'),
              _buildDialButton('8', 'TUV'),
              _buildDialButton('9', 'WXYZ'),
              _buildDialButton('*', ''),
              _buildDialButton('0', '+'),
              _buildDialButton('#', ''),
            ],
          ),
          const SizedBox(height: 5.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.call, color: Colors.green, size: 36.0),
                onPressed: _dialedNumber.isEmpty ? null : _onCallPressed,
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface, size: 36.0),
                onPressed: widget.onClose,
              ),
              IconButton(
                icon: Icon(Icons.backspace, color: theme.colorScheme.onSurface, size: 36.0),
                onPressed: _dialedNumber.isEmpty ? null : _onBackspacePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialButton(String digit, String letters) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _onDigitPressed(digit),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.secondary.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}