import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'slidebar.dart';
import 'Theme.dart';
import 'shared.dart';
import 'dialpad.dart';

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
  final ScrollController _scrollController = ScrollController();

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
          currentOffset += 36.0;
        }
        if (offset < currentOffset + 60.0) {
          if (_selectedLetter != currentTag) {
            setState(() {
              _selectedLetter = currentTag;
            });
          }
          break;
        }
        currentOffset += 60.0;
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

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      print('Fetched contacts: ${contacts.map((c) => c.displayName).toList()}'); // Debug

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
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching contacts: $e';
        _isLoading = false;
      });
      print('Fetch error: $e'); // Debug
    }
  }

  void _showContactDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            sanitizeString(contact.displayName),
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
                  contact.phones.isNotEmpty ? sanitizeString(contact.phones.first.number) : 'No number',
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

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
            Text('No contacts found', style: theme.textTheme.bodyLarge),
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
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 29.0, top: 8.0),
            child: Text(
              currentTag!,
              style: theme.textTheme.titleLarge,
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
              backgroundColor: letterColors[contact.tag] ?? theme.colorScheme.primary,
              radius: 25,
              child: Text(
                sanitizeString(contact.contact.displayName).isNotEmpty
                    ? sanitizeString(contact.contact.displayName)[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              sanitizeString(contact.contact.displayName),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16.0,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    contact.contact.phones.isNotEmpty
                        ? sanitizeString(contact.contact.phones.first.number)
                        : 'No number',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            onTap: () => _showContactDialog(contact.contact),
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
          padding: const EdgeInsets.only(right: 8.0),
          child: CustomIndexBar(
            indexBarData: _indexBarData,
            scrollController: _scrollController,
            onLetterSelected: (letter) {
              int targetIndex = _contacts.indexWhere((contact) => contact.tag == letter);
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
                  targetIndex = _contacts.indexWhere((contact) => contact.tag == closestLetter);
                }
              }

              if (targetIndex != -1) {
                double offset = 0.0;
                String? currentTag;
                for (int i = 0; i < _contacts.length; i++) {
                  final contact = _contacts[i];
                  bool isNewTag = contact.tag != currentTag;
                  if (isNewTag) {
                    currentTag = contact.tag;
                    offset += 36.0;
                  }

                  if (i == targetIndex) {
                    break;
                  }

                  offset += 60.0;
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 18.0),
              child: IconButton(
                icon: Icon(Icons.search, color: theme.colorScheme.onPrimary, size: 30.0),
                onPressed: () {
                  print('Search icon pressed, contacts: ${_contacts.length}'); // Debug
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchPage(contacts: _contacts),
                    ),
                  );
                },
              ),
            ),
            centerTitle: true,
            title: Text(
              widget.title,
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: theme.colorScheme.primary,
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: theme.colorScheme.onPrimary,
                  size: 25.0,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary, size: 25.0),
                onPressed: _fetchContacts,
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class SearchPage extends StatefulWidget {
  final List<ContactModel> contacts;

  const SearchPage({super.key, required this.contacts});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ContactModel> _filteredContacts = [];
  List<String> _searchHistory = [];
  Set<String> _removedSearches = {};

  @override
  void initState() {
    super.initState();
    print('SearchPage init, contacts: ${widget.contacts.length}'); // Debug
    // Initialize _filteredContacts as empty
    _filteredContacts = [];
    _loadSearchHistory();
    _searchController.addListener(_filterContacts);
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    final removed = (prefs.getStringList('removed_searches') ?? []).toSet();
    history.removeWhere((item) => removed.contains(item));
    print('Loaded history: $history, Removed: $removed'); // Debug
    setState(() {
      _searchHistory = history;
      _removedSearches = removed;
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || _removedSearches.contains(trimmedQuery)) {
      print('Skipped saving: $trimmedQuery (empty or removed)'); // Debug
      return;
    }

    final contactMatch = widget.contacts.any((contact) =>
    sanitizeString(contact.contact.displayName).toLowerCase() == trimmedQuery.toLowerCase());
    print('Saving query: $trimmedQuery, Match: $contactMatch'); // Debug

    if (!contactMatch) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory.remove(trimmedQuery);
      _searchHistory.insert(0, trimmedQuery);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10);
      }
      prefs.setStringList('search_history', _searchHistory);
      print('Saved history: $_searchHistory'); // Debug
    });
  }

  Future<void> _removeSearchHistoryItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory.remove(query);
      _removedSearches.add(query);
      prefs.setStringList('search_history', _searchHistory);
      prefs.setStringList('removed_searches', _removedSearches.toList());
      print('Removed: $query, History: $_searchHistory'); // Debug
    });
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _removedSearches.addAll(_searchHistory);
      _searchHistory.clear();
      prefs.setStringList('search_history', _searchHistory);
      prefs.setStringList('removed_searches', _removedSearches.toList());
      print('Cleared all history'); // Debug
    });
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase().trim();
    print('Filtering: $query'); // Debug
    setState(() {
      if (query.isNotEmpty) {
        _saveSearchHistory(query);
        _filteredContacts = widget.contacts.where((contact) {
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

  void _showContactDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            sanitizeString(contact.displayName),
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
                  contact.phones.isNotEmpty ? sanitizeString(contact.phones.first.number) : 'No number',
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

  void _showDialpad() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Dialpad(
        searchController: _searchController,
        onFilterContacts: _filterContacts,
        onClose: () => Navigator.pop(context),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print('Building SearchPage, History: $_searchHistory, Search text: ${_searchController.text}'); // Debug

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          'Search Contacts',
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onPrimary),
          onPressed: () {
            print('Close icon pressed'); // Debug
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter name or number',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface),
                suffixIcon: IconButton(
                  icon: Icon(Icons.dialpad, color: theme.colorScheme.onSurface),
                  onPressed: _showDialpad,
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
              onSubmitted: (value) {
                print('Submitted: $value'); // Debug
                _saveSearchHistory(value);
              },
            ),
          ),
          if (_searchController.text.isEmpty && _searchHistory.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              width: double.infinity,
              color: theme.colorScheme.surface.withOpacity(0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: theme.textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: _clearSearchHistory,
                        child: Text(
                          'Clear All',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _searchHistory.map((query) {
                      return GestureDetector(
                        onTap: () {
                          print('Tapped history: $query'); // Debug
                          _searchController.text = query;
                          _filterContacts();
                        },
                        child: Chip(
                          label: Text(query),
                          onDeleted: () => _removeSearchHistoryItem(query),
                          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                          labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                          deleteButtonTooltipMessage: 'Remove search',
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? _searchController.text.isNotEmpty
                ? Center(
              child: Text(
                'No contacts found',
                style: theme.textTheme.bodyLarge,
              ),
            )
                : const SizedBox.shrink() // No contacts shown when empty
                : ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return SizedBox(
                  height: 60.0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: letterColors[contact.tag] ?? theme.colorScheme.primary,
                      radius: 20,
                      child: Text(
                        sanitizeString(contact.contact.displayName).isNotEmpty
                            ? sanitizeString(contact.contact.displayName)[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    title: Text(
                      sanitizeString(contact.contact.displayName),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16.0,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            contact.contact.phones.isNotEmpty
                                ? sanitizeString(contact.contact.phones.first.number)
                                : 'No number',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showContactDialog(contact.contact),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }
}