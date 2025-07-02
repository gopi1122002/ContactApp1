import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

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
    if (_dialedNumber.isEmpty) return;
    setState(() {
      _dialedNumber = _dialedNumber.substring(0, _dialedNumber.length - 1);
      widget.searchController.text = _dialedNumber;
      widget.onFilterContacts();
    });
  }

  Future<void> _onCallPressed() async {
    if (_dialedNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No number entered')),
        );
      }
      print('No number entered');
      return;
    }

    // Sanitize to keep digits and +
    final sanitizedNumber = _dialedNumber.replaceAll(RegExp(r'[^\d+]'), '');
    // Minimal validation: at least 3 digits
    if (sanitizedNumber.isEmpty || !RegExp(r'^\+?\d{3,}$').hasMatch(sanitizedNumber)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid phone number format: $sanitizedNumber')),
        );
      }
      print('Invalid phone number format: $sanitizedNumber');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // Request CALL_PHONE permission
        var status = await Permission.phone.status;
        if (!status.isGranted) {
          status = await Permission.phone.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call permission denied')),
              );
            }
            print('Call permission denied for number: $sanitizedNumber');
            return;
          }
        }
      }

      // Initiate direct call
      final bool? callSuccess = await FlutterPhoneDirectCaller.callNumber(sanitizedNumber);
      if (callSuccess != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate call')),
        );
        print('Failed to initiate call for number: $sanitizedNumber');
      } else {
        print('Call initiated successfully for $sanitizedNumber');
        widget.onClose(); // Close dialpad after initiating call
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initiating call: $e')),
        );
      }
      print('Error initiating call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: true,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: theme.colorScheme.surface,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // Limit max height
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(), // Prevent overscroll bounce
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar with centered number display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: theme.colorScheme.onSurface, size: 32.0),
                      onPressed: widget.onClose,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 40.0, // Fixed height for number display
                        child: Text(
                          _dialedNumber.isEmpty ? ' ' : _dialedNumber,
                          textAlign: TextAlign.center, // Center text
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: _dialedNumber.length > 15 ? 20.0 : 24.0, // Smaller font for long numbers
                            color: _dialedNumber.isEmpty
                                ? theme.colorScheme.onSurface.withOpacity(0.6)
                                : theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                          maxLines: 1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dialedNumber.isEmpty ? null : _onBackspacePressed,
                      onLongPress: () {
                        setState(() {
                          _dialedNumber = '';
                          widget.searchController.clear();
                          widget.onFilterContacts();
                        });
                      },
                      child: Icon(
                        Icons.backspace,
                        size: 32.0,
                        color: _dialedNumber.isEmpty
                            ? theme.disabledColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Dial buttons
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 20.0,
                childAspectRatio: 1.6,
                physics: const NeverScrollableScrollPhysics(),
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

              const SizedBox(height: 16.0),

              // Call button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _dialedNumber.isEmpty ? null : _onCallPressed,
                      borderRadius: BorderRadius.circular(30.0),
                      splashColor: Colors.white.withOpacity(0.5), // Enhanced splash effect
                      highlightColor: Colors.green.shade200.withOpacity(0.3), // Light green highlight
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        height: 56.0,
                        decoration: BoxDecoration(
                          color: _dialedNumber.isEmpty
                              ? Colors.green.shade400.withOpacity(0.5) // Softer green when disabled
                              : Colors.green.shade600, // Vibrant green when enabled
                          borderRadius: BorderRadius.circular(30.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade700.withOpacity(0.3),
                              blurRadius: 8.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call, color: Colors.white, size: 28.0),
                            SizedBox(width: 8.0),
                            Text(
                              'Call',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialButton(String digit, String letters) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(50.0),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50.0),
            color: theme.colorScheme.secondary.withOpacity(0.2),
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
      ),
    );
  }
}