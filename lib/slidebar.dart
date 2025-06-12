import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

// Sanitize strings to remove invalid UTF-16 characters
String sanitizeString(String input) {
  return input.replaceAll(RegExp(r'[\uD800-\uDFFF]'), '?').replaceAll('\ufffd', '?');
}

class ContactDetails extends StatelessWidget {
  final Contact contact;

  const ContactDetails({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sanitizeString(contact.displayName)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${sanitizeString(contact.displayName)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Phone: ${contact.phones.isNotEmpty ? sanitizeString(contact.phones.first.number) : 'No number'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactModel {
  final Contact contact;
  final String tag;
  final GlobalKey key;

  ContactModel({required this.contact, required this.tag, required this.key});
}

class MyContact extends StatefulWidget {
  const MyContact({super.key, required this.title});
  final String title;

  @override
  State<MyContact> createState() => _MyContactState();
}

class _MyContactState extends State<MyContact> {
  List<ContactModel> _contacts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedLetter;
  List<String> _indexBarData = [];
  DateTime? _lastDragTime;
  OverlayEntry? _overlayEntry;
  String? _currentHintLetter;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _indexBarKey = GlobalKey();





  final Map<String, Color> _letterColors = {
    'A': Colors.blue[100]!,
    'B': Colors.green[100]!,
    'C': Colors.yellow[100]!,
    'D': Colors.pink[100]!,
    'E': Colors.cyan[100]!,
    'F': Colors.amber[100]!,
    'G': Colors.purple[100]!,
    'H': Colors.teal[100]!,
    'I': Colors.lime[100]!,
    'J': Colors.orange[100]!,
    'K': Colors.indigo[100]!,
    'L': Colors.red[100]!,
    'M': Colors.blue[200]!,
    'N': Colors.green[200]!,
    'O': Colors.yellow[200]!,
    'P': Colors.pink[200]!,
    'Q': Colors.cyan[200]!,
    'R': Colors.amber[200]!,
    'S': Colors.purple[200]!,
    'T': Colors.teal[200]!,
    'U': Colors.lime[200]!,
    'V': Colors.orange[200]!,
    'W': Colors.indigo[200]!,
    'X': Colors.red[200]!,
    'Y': Colors.blue[300]!,
    'Z': Colors.green[300]!,
  };

  @override
  void initState() {
    super.initState();
    _fetchContacts();

    _scrollController.addListener(() {
      double offset = _scrollController.offset;
      double currentOffset = 0.0;
      String? currentTag;

      for (var contact in _contacts) {
        if (contact.tag != currentTag) {
          currentTag = contact.tag;
          currentOffset += 36.0; // Section header height
        }
        if (offset < currentOffset + 60.0) { // If scroll position is within this contact
          if (_selectedLetter != contact.tag) {
            setState(() {
              _selectedLetter = contact.tag;
            });
          }
          break;
        }
        currentOffset += 60.0; // Each contact tile height
      }
    });
  }
  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedLetter = null;
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

      // Mock contacts for testing (uncomment to use)
      /*
      final contacts = [
        Contact(displayName: 'Alice', phones: [Phone('123')]),
        Contact(displayName: 'Bob', phones: [Phone('456')]),
        Contact(displayName: 'Charlie', phones: [Phone('789')]),
        Contact(displayName: 'Emma', phones: [Phone('012')]),
        Contact(displayName: 'Frank', phones: [Phone('345')]),
      ];
      */
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      List<ContactModel> items = contacts.map((c) {
        String tag = c.displayName.isNotEmpty ? sanitizeString(c.displayName)[0].toUpperCase() : '';
        if (!RegExp(r'[A-Z]').hasMatch(tag)) return null;
        return ContactModel(contact: c, tag: tag, key: GlobalKey());
      }).whereType<ContactModel>().toList();

      items.sort((a, b) => sanitizeString(a.contact.displayName).toLowerCase().compareTo(sanitizeString(b.contact.displayName).toLowerCase()));

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
        print('Available letters: $_indexBarData');
        print('Contacts: ${_contacts.map((c) => "${c.contact.displayName} (${c.tag})").join(", ")}');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching contacts: $e';
        _isLoading = false;
      });
    }
  }

  void _scrollToLetter(String letter) {
    final now = DateTime.now();
    if (_lastDragTime != null && now.difference(_lastDragTime!).inMilliseconds < 50) {
      return;
    }
    _lastDragTime = now;

    HapticFeedback.selectionClick();

    setState(() {
      _selectedLetter = letter.toUpperCase();
      print('Tapped letter: $_selectedLetter');
    });

    // Find the target index and calculate offset
    int targetIndex = _contacts.indexWhere((contact) => contact.tag == _selectedLetter);
    if (targetIndex == -1) {
      print('No contacts for $_selectedLetter, finding closest letter');
      // Find the closest available letter
      final allLetters = ['#', ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')];
      final currentIndex = allLetters.indexOf(_selectedLetter!);
      String? closestLetter;

      // Look for the next available letter
      for (int i = currentIndex + 1; i < allLetters.length; i++) {
        if (_indexBarData.contains(allLetters[i])) {
          closestLetter = allLetters[i];
          break;
        }
      }
      // If no letter found after, look before
      if (closestLetter == null) {
        for (int i = currentIndex - 1; i >= 0; i--) {
          if (_indexBarData.contains(allLetters[i])) {
            closestLetter = allLetters[i];
            break;
          }
        }
      }

      if (closestLetter != null) {
        _selectedLetter = closestLetter;
        targetIndex = _contacts.indexWhere((contact) => contact.tag == closestLetter);
        print('Scrolling to closest letter: $closestLetter');
      }
    }

    if (targetIndex != -1) {
      print('Scrolling to contact: ${_contacts[targetIndex].contact.displayName}');
      // Calculate offset: section header (36.0) + contact items (60.0 each)
      int itemIndex = 0;
      double offset = 0.0;
      String? currentTag;
      for (int i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];
        bool isNewTag = contact.tag != currentTag;
        if (isNewTag) {
          currentTag = contact.tag;
          offset += 36.0; // Header height
        }

        if (i == targetIndex) {
          break;
        }

        offset += 60.0; // Contact tile height
      }

      // Jump immediately to the calculated offset
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      print('No valid target found, scrolling to top');
      _scrollController.jumpTo(0.0);
    }
  }
  void _showIndexHint(String letter, Offset globalPosition) {
    _removeIndexHint();

    final overlay = Overlay.of(context);
    final RenderBox box = _indexBarKey.currentContext!.findRenderObject() as RenderBox;
    final barPosition = box.localToGlobal(Offset.zero);

    final screenHeight = MediaQuery.of(context).size.height;
    double topOffset = globalPosition.dy - 20;
    double bottomPadding = 20.0;
    topOffset = topOffset.clamp(20.0, screenHeight - bottomPadding);topOffset = topOffset.clamp(10.0, screenHeight - 60.0);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topOffset,
        left: barPosition.dx - 60, // Show to the left of index bar
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 70,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 36, // bigger text for better visibility
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeIndexHint() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }


  Widget _buildCustomIndexBar() {
    return Container(
      key: _indexBarKey,
      width: 36.0,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // top align
          children: _indexBarData.map((letter) {
            return GestureDetector(
              onTapDown: (details) {
                _showIndexHint(letter, details.globalPosition);
                _scrollToLetter(letter);
              },
              onTapCancel: _removeIndexHint,
              onTapUp: (_) => _removeIndexHint(),
              onVerticalDragUpdate: (details) {
                final RenderBox box = _indexBarKey.currentContext!.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final heightPerLetter = box.size.height / _indexBarData.length;
                final index = (localPosition.dy / heightPerLetter).clamp(0, _indexBarData.length - 1).toInt();
                final selectedLetter = _indexBarData[index];
                _showIndexHint(selectedLetter, details.globalPosition);
                _scrollToLetter(selectedLetter);
              },
              onVerticalDragEnd: (_) => _removeIndexHint(),
              child: Container(
                height: 30.0, // Increased for better touch area
                width: 30.0,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(vertical: 3.0),
                decoration: BoxDecoration(
                  color: _letterColors[letter] ?? Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }




  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchContacts,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open App Settings'),
            ),
          ],
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No contacts found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchContacts,
              child: const Text('Load Contacts'),
            ),
          ],
        ),
      );
    }

    List<Widget> listItems = [];
    String? currentTag;
    for (var contact in _contacts) {
      if (contact.tag != currentTag) {
        currentTag = contact.tag;
        listItems.add(
          Container(
            height: 36.0,
            width: double.infinity,
            color: _letterColors[currentTag] ?? Colors.grey[300],
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              currentTag!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        );
      }
      listItems.add(
        SizedBox(
          height: 60.0,
          child: ListTile(
            key: contact.key,
            leading: CircleAvatar(
              backgroundColor: _letterColors[contact.tag] ?? _letterColors['#']!,
              radius: 20,
              child: Text(
                sanitizeString(contact.contact.displayName).isNotEmpty
                    ? sanitizeString(contact.contact.displayName)[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              sanitizeString(contact.contact.displayName),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              contact.contact.phones.isNotEmpty
                  ? sanitizeString(contact.contact.phones.first.number)
                  : 'No number',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetails(contact: contact.contact),
                ),
              );
            },
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: listItems.length,
            itemBuilder: (context, index) => listItems[index],
            cacheExtent: 2000.0,
          ),
        ),
        Padding(
        padding: const EdgeInsets.only(right: 8.0), // Move index bar left
    child: _buildCustomIndexBar(),
       )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Contacts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchContacts,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}