import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'shared.dart';
import 'contact.dart'; // Import for IndexBarColorMode enum

class CustomIndexBar extends StatefulWidget {
  final List<String> indexBarData;
  final ScrollController scrollController;
  final Function(String) onLetterSelected;
  final IndexBarColorMode colorMode;

  const CustomIndexBar({
    super.key,
    required this.indexBarData,
    required this.scrollController,
    required this.onLetterSelected,
    required this.colorMode,
  });

  @override
  State<CustomIndexBar> createState() => _CustomIndexBarState();
}

class _CustomIndexBarState extends State<CustomIndexBar> {
  DateTime? _lastDragTime;
  OverlayEntry? _overlayEntry;
  String? _currentHintLetter;
  final GlobalKey _indexBarKey = GlobalKey();
  final ScrollController indexBarScrollController = ScrollController(); // Moved to class level

  void _scrollToLetter(String letter) {
    final now = DateTime.now();
    if (_lastDragTime != null && now.difference(_lastDragTime!).inMilliseconds < 50) {
      return;
    }
    _lastDragTime = now;

    HapticFeedback.selectionClick();

    widget.onLetterSelected(letter.toUpperCase());
  }

  void _showIndexHint(String letter, Offset globalPosition, {required double scrollOffset, required double heightPerLetter}) {
    _removeIndexHint();

    final overlay = Overlay.of(context);
    final RenderBox? box = _indexBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final barPosition = box.localToGlobal(Offset.zero);
    final barHeight = box.size.height;
    final screenHeight = MediaQuery.of(context).size.height;
    final letterIndex = widget.indexBarData.indexOf(letter);

    double letterTop = letterIndex * heightPerLetter - scrollOffset;
    double topOffset = barPosition.dy + letterTop + (heightPerLetter / 2) - 35.0;

    if (letterIndex < 0) {
      final localPosition = box.globalToLocal(globalPosition);
      topOffset = barPosition.dy + localPosition.dy - 35.0;
    }

    topOffset = topOffset.clamp(
      barPosition.dy + 8.0,
      barPosition.dy + barHeight - 70.0 - 8.0,
    );

    topOffset = topOffset.clamp(20.0, screenHeight - 70.0);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            top: topOffset,
            left: barPosition.dx - 80.0,
            child: Material(
              elevation: 0.0,
              color: Colors.transparent,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeIndexHint() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    const double heightPerLetter = 54.0;
    final theme = Theme.of(context);

    return Container(
      key: _indexBarKey,
      width: 40.0,
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            if (_currentHintLetter != null && _overlayEntry != null) {
              final letterIndex = widget.indexBarData.indexOf(_currentHintLetter!);
              if (letterIndex >= 0) {
                final RenderBox? box = _indexBarKey.currentContext?.findRenderObject() as RenderBox?;
                if (box == null) return false;
                final barPosition = box.localToGlobal(Offset.zero);
                double letterTop = letterIndex * heightPerLetter - indexBarScrollController.offset;
                double topOffset = barPosition.dy + letterTop + (heightPerLetter / 2) - 35.0;
                topOffset = topOffset.clamp(20.0, MediaQuery.of(context).size.height - 70.0);
                _overlayEntry?.remove();
                _overlayEntry = OverlayEntry(
                  builder: (context) => Stack(
                    children: [
                      Positioned(
                        top: topOffset,
                        left: barPosition.dx - 80.0,
                        child: Material(
                          elevation: 0.0,
                          color: Colors.transparent,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _currentHintLetter!,
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                Overlay.of(context).insert(_overlayEntry!);
              }
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: indexBarScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: widget.indexBarData.map((letter) {
              return GestureDetector(
                onTapDown: (details) {
                  setState(() {
                    _currentHintLetter = letter;
                  });
                  _showIndexHint(
                    letter,
                    details.globalPosition,
                    scrollOffset: indexBarScrollController.offset,
                    heightPerLetter: heightPerLetter,
                  );
                  _scrollToLetter(letter);
                },
                onTapCancel: () {
                  setState(() {
                    _currentHintLetter = null;
                  });
                  _removeIndexHint();
                },
                onTapUp: (_) {
                  setState(() {
                    _currentHintLetter = null;
                  });
                  _removeIndexHint();
                },
                onVerticalDragStart: (details) {
                  setState(() {
                    _currentHintLetter = letter;
                  });
                  _showIndexHint(
                    letter,
                    details.globalPosition,
                    scrollOffset: indexBarScrollController.offset,
                    heightPerLetter: heightPerLetter,
                  );
                  _scrollToLetter(letter);
                },
                onVerticalDragUpdate: (details) {
                  final RenderBox box = _indexBarKey.currentContext!.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.globalPosition);
                  final adjustedPosition = localPosition.dy + indexBarScrollController.offset;
                  final index = (adjustedPosition / heightPerLetter).clamp(0, widget.indexBarData.length - 1).toInt();
                  final selectedLetter = widget.indexBarData[index];
                  final letterTop = index * heightPerLetter;
                  final viewportHeight = box.size.height;
                  final targetOffset = (letterTop - (viewportHeight / 2) + (heightPerLetter / 2)).clamp(0.0, indexBarScrollController.position.maxScrollExtent);
                  indexBarScrollController.animateTo(
                    targetOffset,
                    duration: const Duration(milliseconds: 50),
                    curve: Curves.easeOut,
                  );

                  setState(() {
                    _currentHintLetter = selectedLetter;
                  });
                  _showIndexHint(
                    selectedLetter,
                    details.globalPosition,
                    scrollOffset: indexBarScrollController.offset,
                    heightPerLetter: heightPerLetter,
                  );
                  _scrollToLetter(selectedLetter);
                },
                onVerticalDragEnd: (_) {
                  setState(() {
                    _currentHintLetter = null;
                  });
                  _removeIndexHint();
                },
                child: Container(
                  height: 46.0,
                  width: 60.0,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    color: widget.colorMode == IndexBarColorMode.transparent
                        ? Colors.transparent
                        : (letterColors[letter]?.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1) ?? theme.colorScheme.surface),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    indexBarScrollController.dispose();
    _removeIndexHint();
    super.dispose();
  }
}