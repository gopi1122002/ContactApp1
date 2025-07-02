import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'slidebar.dart';
import 'Theme.dart';
import 'shared.dart';
import 'dialpad.dart';
import 'add_contacts.dart';

class ContactModel {
  final Contact contact;
  final String tag;
  final GlobalKey key;

  ContactModel({required this.contact, required this.tag, required this.key});
}

enum ContactDisplayLevel {
  level1,
  level2,
  level3,
}

enum IndexBarColorMode {
  transparent,
  multicolor,
}

class CustomFabLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset defaultOffset = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    return Offset(defaultOffset.dx - 8.0, defaultOffset.dy - 8.0);
  }
}

class MyContact extends StatefulWidget {
  const MyContact({super.key, required this.title});
  final String title;

  @override
  State<MyContact> createState() => _MyContactState();
}

class _MyContactState extends State<MyContact> {
  List<ContactModel> _contacts = [];
  List<ContactModel> _filteredContacts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedLetter;
  List<String> _indexBarData = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  ContactDisplayLevel _displayLevel = ContactDisplayLevel.level1;
  IndexBarColorMode _indexBarColorMode = IndexBarColorMode.multicolor;
  bool _showIndexBar = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _loadDisplayLevel();
    _loadIndexBarColorMode();
    _loadIndexBarVisibility();

    _scrollController.addListener(() {
      if (!_showIndexBar) return;
      double offset = _scrollController.offset;
      double currentOffset = 0.0;
      String? currentTag;

      for (var contact in _filteredContacts.isEmpty ? _contacts : _filteredContacts) {
        if (contact.tag != currentTag) {
          currentTag = contact.tag;
          currentOffset += 48.0;
        }
        if (offset < currentOffset + _getContactHeight()) {
          if (_selectedLetter != currentTag) {
            setState(() {
              _selectedLetter = currentTag;
            });
          }
          break;
        }
        currentOffset += _getContactHeight();
      }
    });

    _searchController.addListener(_filterContacts);
  }

  Future<void> _loadIndexBarVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showIndexBar = prefs.getBool('show_index_bar') ?? true;
    });
  }

  Future<void> _toggleIndexBarVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showIndexBar = !_showIndexBar;
      prefs.setBool('show_index_bar', _showIndexBar);
    });
  }

  Future<void> _loadIndexBarColorMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString('index_bar_color_mode') ?? 'multicolor';
    setState(() {
      _indexBarColorMode = IndexBarColorMode.values.firstWhere(
            (e) => e.toString().split('.').last == modeString,
        orElse: () => IndexBarColorMode.multicolor,
      );
    });
  }

  Future<void> _setIndexBarColorMode(IndexBarColorMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('index_bar_color_mode', mode.toString().split('.').last);
    setState(() {
      _indexBarColorMode = mode;
    });
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isNotEmpty) {
        _filteredContacts = _contacts.where((contact) {
          final name = sanitizeString(contact.contact.displayName).toLowerCase();
          final number = contact.contact.phones.isNotEmpty
              ? sanitizeString(contact.contact.phones.first.number).toLowerCase()
              : '';
          return name.contains(query) || number.contains(query);
        }).toList();
      } else {
        _filteredContacts = [];
      }
    });
  }

  Future<void> _loadDisplayLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString('contact_display_level') ?? 'level1';
    setState(() {
      _displayLevel = ContactDisplayLevel.values.firstWhere(
            (e) => e.toString().split('.').last == modeString,
        orElse: () => ContactDisplayLevel.level1,
      );
    });
  }

  Future<void> _saveDisplayLevel(ContactDisplayLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contact_display_level', level.toString().split('.').last);
    setState(() {
      _displayLevel = level;
    });
  }

  double _getContactHeight() {
    switch (_displayLevel) {
      case ContactDisplayLevel.level1:
        return 90.0;
      case ContactDisplayLevel.level2:
        return 100.0;
      case ContactDisplayLevel.level3:
        return 110.0;
    }
  }

  double _getAvatarRadius() {
    switch (_displayLevel) {
      case ContactDisplayLevel.level1:
        return 30.0;
      case ContactDisplayLevel.level2:
        return 36.0;
      case ContactDisplayLevel.level3:
        return 44.0;
    }
  }

  TextStyle _getAvatarTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    switch (_displayLevel) {
      case ContactDisplayLevel.level1:
        return TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 22.0,
          fontWeight: FontWeight.w400,
        );
      case ContactDisplayLevel.level2:
        return TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 28.0,
          fontWeight: FontWeight.w500,
        );
      case ContactDisplayLevel.level3:
        return TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 30.0,
          fontWeight: FontWeight.w700,
        );
    }
  }

  TextStyle _getContactTextStyle(BuildContext context, {required bool isName}) {
    final theme = Theme.of(context);
    switch (_displayLevel) {
      case ContactDisplayLevel.level1:
        return isName
            ? theme.textTheme.bodyLarge?.copyWith(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
        ) ??
            const TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal)
            : theme.textTheme.bodyMedium?.copyWith(fontSize: 14.0) ??
            const TextStyle(fontSize: 14.0);
      case ContactDisplayLevel.level2:
        return isName
            ? theme.textTheme.bodyLarge?.copyWith(
          fontSize: 18.0,
          fontWeight: FontWeight.normal,
        ) ??
            const TextStyle(fontSize: 18.0, fontWeight: FontWeight.normal)
            : theme.textTheme.bodyMedium?.copyWith(fontSize: 16.0) ??
            const TextStyle(fontSize: 16.0);
      case ContactDisplayLevel.level3:
        return isName
            ? theme.textTheme.bodyLarge?.copyWith(
          fontSize: 20.0,
          fontWeight: FontWeight.normal,
        ) ??
            const TextStyle(fontSize: 20.0, fontWeight: FontWeight.normal)
            : theme.textTheme.bodyMedium?.copyWith(fontSize: 18.0) ??
            const TextStyle(fontSize: 18.0);
    }
  }

  EdgeInsets _getContactPadding() {
    switch (_displayLevel) {
      case ContactDisplayLevel.level1:
        return const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0);
      case ContactDisplayLevel.level2:
        return const EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0);
      case ContactDisplayLevel.level3:
        return const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0);
    }
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedLetter = null;
      _searchController.clear();
      _filteredContacts = [];
    });

    try {
      var status = await Permission.contacts.status;
      if (!status.isGranted) {
        status = await Permission.contacts.request();
        if (!status.isGranted) {
          setState(() {
            _errorMessage = 'Contact permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: true);
      List<ContactModel> items = contacts.map((c) {
        String tag = c.displayName.isNotEmpty ? sanitizeString(c.displayName)[0].toUpperCase() : '';
        if (!RegExp(r'[A-Z]').hasMatch(tag)) return null;
        return ContactModel(contact: c, tag: tag, key: GlobalKey());
      }).whereType<ContactModel>().toList();

      items.sort((a, b) => sanitizeString(a.contact.displayName).toLowerCase()
          .compareTo(sanitizeString(b.contact.displayName).toLowerCase()));

      final allTags = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
      final availableTags = <String>[];
      for (var tag in allTags) {
        if (items.any((contact) => contact.tag == tag)) {
          availableTags.add(tag);
        }
      }

      setState(() {
        _contacts = items;
        _indexBarData = availableTags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching contacts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteContact(Contact contact) async {
    try {
      await FlutterContacts.deleteContact(contact);
      await _fetchContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting contact: $e')),
        );
      }
    }
  }

  Future<bool> _confirmDelete(Contact contact) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 200.0,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete ${sanitizeString(contact.displayName)}?',
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Delete all history for this number?',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface)),
                    ),
                    const SizedBox(width: 8.0),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ??
        false;
  }

  Future<void> _makeCall(ContactModel contact) async {
    // Directly attempt to initiate the call
    await _initiateCall(contact);
  }

  Future<void> _initiateCall(ContactModel contact) async {
    if (contact.contact.phones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
      print('No phone number available for contact: ${contact.contact.displayName}');
      return;
    }

    String? phoneNumber;
    if (contact.contact.phones.length > 1) {
      phoneNumber = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select a number for ${contact.contact.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: contact.contact.phones
                  .map((phone) => ListTile(
                title: Text(phone.number),
                onTap: () => Navigator.pop(context, phone.number),
              ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (phoneNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call cancelled')),
          );
        }
        print('Call cancelled by user');
        return;
      }
    } else {
      phoneNumber = contact.contact.phones.first.number;
    }

    // Sanitize to keep digits and +
    final sanitizedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
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

  Future<void> _openAppSettingsFallback() async {
    bool opened = await openAppSettings();
    print('openAppSettings result: $opened');
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please open app settings manually')),
      );
    }
  }

  void _showContactDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 200.0,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sanitizeString(contact.displayName),
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 20.0,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        contact.phones.isNotEmpty
                            ? sanitizeString(contact.phones.first.number)
                            : 'No number',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(color: theme.colorScheme.primary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDialpad() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Dialpad(
        searchController: _searchController,
        onFilterContacts: _filterContacts,
        onClose: () {
          Navigator.pop(context);
          print('Dialpad closed, returning to MyContact');
        },
      ),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'v 1.2',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(color: theme.colorScheme.primary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ({Widget body, bool showFab}) _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return (
      body: const Center(child: CircularProgressIndicator()),
      showFab: false,
      );
    }

    if (_errorMessage != null) {
      return (
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchContacts,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _openAppSettingsFallback,
              child: const Text('Open App Settings'),
            ),
          ],
        ),
      ),
      showFab: false,
      );
    }

    if (_contacts.isEmpty || (_searchController.text.isNotEmpty && _filteredContacts.isEmpty)) {
      print('Rendering No contacts found state');
      return (
      body: Stack(
        children: [
          Container(
            color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
          if (_contacts.isEmpty)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 30.0, color: Colors.white),
                    onPressed: () {
                      print('Back arrow pressed');
                      Navigator.pop(context);
                    },
                    tooltip: 'Back',
                  ),
                ),
              ),
            ),
          Column(
            children: [
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search contacts',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear, color: theme.colorScheme.onSurface),
                              onPressed: () {
                                _searchController.clear();
                                _filterContacts();
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.person_add, color: theme.colorScheme.onSurface),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddContactPage()),
                              );
                              await _fetchContacts();
                            },
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: theme.colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                    ),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (value) => _filterContacts(),
                  ),
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Image.asset(
                            'assets/images/no_contacts.png',
                            width: 280,
                            height: 280,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('Image load error: $error');
                              return const Text(
                                'Image not found',
                                style: TextStyle(color: Colors.red),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          'No contacts found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        if (_contacts.isEmpty)
                          ElevatedButton(
                            onPressed: _fetchContacts,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                              textStyle: const TextStyle(fontSize: 16.0),
                            ),
                            child: const Text('Load Contacts'),
                          )
                        else
                          Text(
                            'Try a different search term',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      showFab: false,
      );
    }

    final displayContacts = _filteredContacts.isEmpty && _searchController.text.isEmpty
        ? _contacts
        : _filteredContacts;

    List<Widget> listItems = [];
    String? currentTag;
    for (var contact in displayContacts) {
      if (contact.tag != currentTag) {
        currentTag = contact.tag;
        listItems.add(
          Container(
            height: 48.0,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 29.0, top: 12.0),
            child: Text(
              currentTag!,
              style: theme.textTheme.titleLarge,
            ),
          ),
        );
      }
      listItems.add(
        Dismissible(
          key: Key(contact.contact.id ?? UniqueKey().toString()),
          direction: DismissDirection.horizontal,
          background: Container(
            color: Colors.green,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16.0),
            child: Icon(Icons.phone, color: theme.colorScheme.onPrimary),
          ),
          secondaryBackground: Container(
            color: theme.colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.delete, color: theme.colorScheme.onError),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              print('Swipe left detected for contact: ${contact.contact.displayName}');
              await _makeCall(contact);
              return false; // Prevent dismissing the contact on swipe-to-call
            } else {
              return await _confirmDelete(contact.contact);
            }
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              _deleteContact(contact.contact);
            }
          },
          child: SizedBox(
            height: _getContactHeight(),
            width: double.infinity, // Ensure full width for swipe detection
            child: Padding(
              padding: _getContactPadding(),
              child: ListTile(
                key: contact.key,
                leading: CircleAvatar(
                  backgroundColor: letterColors[contact.tag] ?? theme.colorScheme.primary,
                  radius: _getAvatarRadius(),
                  backgroundImage: contact.contact.photo != null ? MemoryImage(contact.contact.photo!) : null,
                  child: contact.contact.photo == null
                      ? Text(
                    sanitizeString(contact.contact.displayName).isNotEmpty
                        ? sanitizeString(contact.contact.displayName)[0].toUpperCase()
                        : '?',
                    style: _getAvatarTextStyle(context),
                  )
                      : null,
                ),
                title: Text(
                  sanitizeString(contact.contact.displayName),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: _getContactTextStyle(context, isName: true),
                ),
                subtitle: Row(
                  children: [
                    if (contact.contact.phones.isNotEmpty) ...[
                      const SizedBox(width: 4.0),
                      Icon(
                        contact.contact.displayName.isNotEmpty ? Icons.phone : Icons.public,
                        size: 18.0,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4.0),
                    ],
                    Expanded(
                      child: Text(
                        contact.contact.phones.isNotEmpty
                            ? sanitizeString(contact.contact.phones.first.number)
                            : 'No number',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: _getContactTextStyle(context, isName: false),
                      ),
                    ),
                  ],
                ),
                onTap: () => _showContactDialog(contact.contact),
              ),
            ),
          ),
        ),
      );
    }

    return (
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: theme.colorScheme.onSurface),
                      onPressed: () {
                        _searchController.clear();
                        _filterContacts();
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.person_add, color: theme.colorScheme.onSurface),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddContactPage()),
                      );
                      await _fetchContacts();
                    },
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: theme.colorScheme.onSurface),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            ),
            style: theme.textTheme.bodyMedium,
            onChanged: (value) => _filterContacts(),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: listItems,
                ),
              ),
              if (_showIndexBar)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CustomIndexBar(
                    indexBarData: _indexBarData,
                    scrollController: _scrollController,
                    onLetterSelected: (letter) {
                      int targetIndex = displayContacts.indexWhere((contact) => contact.tag == letter);
                      if (targetIndex == -1) {
                        final allLetters = ['#', ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')];
                        final currentIndex = allLetters.indexOf(letter);
                        String? closestLetter;

                        for (int i = currentIndex + 1; i < allLetters.length; i++) {
                          if (_indexBarData.contains(allLetters[i])) {
                            closestLetter = allLetters[i];
                            break;
                          }
                        }
                        if (closestLetter == null) {
                          for (int i = currentIndex - 1; i >= 0; i--) {
                            if (_indexBarData.contains(allLetters[i])) {
                              closestLetter = allLetters[i];
                              break;
                            }
                          }
                        }

                        if (closestLetter != null) {
                          targetIndex = displayContacts.indexWhere((contact) => contact.tag == closestLetter);
                        }
                      }

                      if (targetIndex != -1) {
                        double offset = 0.0;
                        String? currentTag;
                        for (int i = 0; i < displayContacts.length; i++) {
                          final contact = displayContacts[i];
                          bool isNewTag = contact.tag != currentTag;
                          if (isNewTag) {
                            currentTag = contact.tag;
                            offset += 48.0;
                          }

                          if (i == targetIndex) {
                            break;
                          }

                          offset += _getContactHeight();
                        }

                        _scrollController.animateTo(
                          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      } else {
                        _scrollController.jumpTo(0.0);
                      }
                    },
                    colorMode: _indexBarColorMode,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
    showFab: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final theme = Theme.of(context);
        final result = _buildBody();

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: GestureDetector(
              onTap: _fetchContacts,
              child: Text(
                widget.title,
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
            automaticallyImplyLeading: !_contacts.isEmpty,
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.sort, color: theme.colorScheme.onPrimary),
                onSelected: (value) {
                  print('PopupMenuButton selected: $value');
                  if (value == 'toggle_theme') {
                    themeProvider.toggleTheme(!themeProvider.isDarkMode);
                  } else if (value.startsWith('level')) {
                    final level = ContactDisplayLevel.values.firstWhere(
                          (e) => e.toString().split('.').last == value,
                    );
                    _saveDisplayLevel(level);
                  } else if (value == 'transparent_index_bar') {
                    _setIndexBarColorMode(IndexBarColorMode.transparent);
                  } else if (value == 'multicolor_index_bar') {
                    _setIndexBarColorMode(IndexBarColorMode.multicolor);
                  } else if (value == 'toggle_index_bar') {
                    _toggleIndexBarVisibility();
                  } else if (value == 'info') {
                    _showInfoDialog();
                  }
                },
                constraints: const BoxConstraints(maxWidth: 300.0),
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  if (_showIndexBar) ...[
                    PopupMenuItem(
                      value: 'transparent_index_bar',
                      height: 48.0,
                      child: Row(
                        children: [
                          Icon(
                            Icons.opacity,
                            color: _indexBarColorMode == IndexBarColorMode.transparent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            size: 22.0,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Transparent',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: _indexBarColorMode == IndexBarColorMode.transparent
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'multicolor_index_bar',
                      height: 48.0,
                      child: Row(
                        children: [
                          Icon(
                            Icons.color_lens,
                            color: _indexBarColorMode == IndexBarColorMode.multicolor
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            size: 22.0,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Multicolor',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: _indexBarColorMode == IndexBarColorMode.multicolor
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  PopupMenuItem(
                    value: 'toggle_index_bar',
                    height: 48.0,
                    child: Row(
                      children: [
                        Icon(
                          _showIndexBar ? Icons.visibility_off : Icons.visibility,
                          color: theme.colorScheme.onSurface,
                          size: 22.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            _showIndexBar ? 'Hide Alphabet Bar' : 'Show Alphabet Bar',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 8.0),
                  PopupMenuItem(
                    value: 'toggle_theme',
                    height: 48.0,
                    child: Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                          size: 22.0,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 8.0),
                  PopupMenuItem(
                    value: 'level1',
                    height: 48.0,
                    child: Text(
                      'Level 1',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: _displayLevel == ContactDisplayLevel.level1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'level2',
                    height: 48.0,
                    child: Text(
                      'Level 2',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: _displayLevel == ContactDisplayLevel.level2
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'level3',
                    height: 48.0,
                    child: Text(
                      'Level 3',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: _displayLevel == ContactDisplayLevel.level3
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(height: 4.0),
                  PopupMenuItem(
                    value: 'info',
                    height: 48.0,
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: theme.colorScheme.onSurface,
                          size: 22.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Info',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: result.body,
          floatingActionButton: result.showFab
              ? Padding(
            padding: const EdgeInsets.only(bottom: 40.0, right: 40.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: _showDialpad,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 6.0,
                child: const Icon(Icons.dialpad, size: 30.0),
              ),
            ),
          )
              : null,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }
}