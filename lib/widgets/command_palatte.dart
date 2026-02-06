import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/providers/task_provider.dart';
import 'package:focus/screens/desktop_task_edit_screen.dart';

// Represents a single command that can be executed.
class Command {
  final String name;
  final IconData icon;
  final VoidCallback onExecute;

  Command({required this.name, required this.icon, required this.onExecute});
}

// Represents a searchable item in the palette (can be a Command or a Task).
class SearchResult {
  final String title;
  final String type;
  final IconData icon;
  final VoidCallback onExecute;

  SearchResult({
    required this.title,
    required this.type,
    required this.icon,
    required this.onExecute,
  });
}

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
    _search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    final allTasks = ref.read(taskProvider);
    final context = this.context;

    final List<Command> commands = [
      Command(
        name: 'New Task',
        icon: Icons.add_circle_outline,
        onExecute: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DesktopTaskEditScreen(),
            ),
          );
        },
      ),
    ];

    List<SearchResult> results = [];
    final lowerCaseQuery = query.toLowerCase();

    results.addAll(
      commands
          .where((cmd) => cmd.name.toLowerCase().contains(lowerCaseQuery))
          .map(
            (cmd) => SearchResult(
              title: cmd.name,
              type: 'Command',
              icon: cmd.icon,
              onExecute: cmd.onExecute,
            ),
          ),
    );

    if (query.isNotEmpty) {
      results.addAll(
        allTasks
            .where((task) => task.title.toLowerCase().contains(lowerCaseQuery))
            .map(
              (task) => SearchResult(
                title: task.title,
                type: 'Task',
                icon: Icons.article_outlined,
                onExecute: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DesktopTaskEditScreen(task: task),
                    ),
                  );
                },
              ),
            ),
      );
    }

    setState(() {
      _searchResults = results;
      _selectedIndex = 0;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && _searchResults.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _searchResults.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1 + _searchResults.length) %
              _searchResults.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _searchResults[_selectedIndex].onExecute();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      insetPadding: const EdgeInsets.only(
        top: 100,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _handleKeyEvent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _search,
                      autofocus: true,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Type a command or search for a task...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  if (_searchResults.isNotEmpty)
                    LimitedBox(
                      maxHeight: 400,
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          final isSelected = index == _selectedIndex;
                          return ListTile(
                            leading: Icon(
                              result.icon,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              result.title,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              result.type,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: result.onExecute,
                            tileColor: isSelected
                                ? colorScheme.primary.withOpacity(0.1)
                                : null,
                          );
                        },
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No results found.'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
