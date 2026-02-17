import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../blocs/chat_bloc.dart';
import '../../blocs/settings_bloc.dart';
import '../settings/settings_screen.dart';
import '../usage/usage_history_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          const VerticalDivider(width: 1),
          Expanded(child: _buildChatArea(context)),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, int sessionId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ChatBloc>().add(RenameSession(sessionId, controller.text.trim()));
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            final configuredProviders = settingsState.apiKeys.keys.toList();
            
            if (configuredProviders.isEmpty) {
              return AlertDialog(
                title: const Text('No Providers Configured'),
                content: const Text('Please add an API key in Settings first.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            String selectedProvider = configuredProviders.first;
            List<String> models = settingsState.availableModels[selectedProvider] ?? [];
            String? selectedModel = models.isNotEmpty ? models.first : null;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Start New Chat'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedProvider,
                        decoration: const InputDecoration(labelText: 'Provider'),
                        items: configuredProviders.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase()),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedProvider = val;
                              models = settingsState.availableModels[selectedProvider] ?? [];
                              selectedModel = models.isNotEmpty ? models.first : null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedModel,
                        decoration: const InputDecoration(labelText: 'Model'),
                        items: models.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedModel = val);
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: selectedModel == null ? null : () {
                        context.read<ChatBloc>().add(NewSession(
                          providerId: selectedProvider,
                          model: selectedModel!,
                        ));
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Start'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  bool _isSidebarCollapsed = false;

  Widget _buildSidebar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarCollapsed ? 72 : 260,
      color: Colors.transparent, // Background equalized
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSidebarCollapsed)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SvgPicture.asset(
                        'assets/svg/gladden.svg',
                        height: 32,
                        fit: BoxFit.fitHeight,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? LucideIcons.panelLeftOpen : LucideIcons.panelLeftClose,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  tooltip: _isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.05)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isSidebarCollapsed
                ? IconButton(
                    onPressed: () => _showNewChatDialog(context),
                    icon: const Icon(LucideIcons.plusCircle, color: Colors.blueAccent),
                    tooltip: 'New Chat',
                  )
                : ElevatedButton.icon(
                    onPressed: () => _showNewChatDialog(context),
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('New Chat'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      foregroundColor: Colors.blueAccent,
                      elevation: 0,
                    ),
                  ),
          ),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return ListView.builder(
                  itemCount: state.sessions.length,
                  itemBuilder: (context, index) {
                    final session = state.sessions[index];
                    final isSelected = state.currentSession?.id == session.id;
                    
                    if (_isSidebarCollapsed) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.messageSquare, 
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => context.read<ChatBloc>().add(SelectSession(session.id)),
                          tooltip: session.title.isEmpty ? 'Untitled Chat' : session.title,
                        ),
                      );
                    }

                    return ListTile(
                      title: Text(
                        session.title.isEmpty ? 'Untitled Chat' : session.title, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      trailing: isSelected 
                        ? IconButton(
                            icon: const Icon(LucideIcons.pencil, size: 14, color: Colors.white54),
                            onPressed: () => _showRenameDialog(context, session.id, session.title),
                          )
                        : null,
                      onTap: () => context.read<ChatBloc>().add(SelectSession(session.id)),
                    );
                  },
                );
              },
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.05)),
          if (!_isSidebarCollapsed)
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final totalCost = state.currentSession?.messages.fold<double>(
                  0, (sum, m) => sum + (m.estimatedCost ?? 0)
                ) ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.dollarSign, size: 14, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            '\$${totalCost.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Session Cost (Est.)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          if (_isSidebarCollapsed)
             IconButton(
               icon: const Icon(LucideIcons.settings, color: Colors.white70),
               onPressed: () => Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const SettingsScreen()),
               ),
               tooltip: 'Settings',
             )
          else
            ListTile(
              leading: const Icon(LucideIcons.settings, size: 20, color: Colors.white70),
              title: const Text('Settings', style: TextStyle(fontSize: 14, color: Colors.white70)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<ChatBloc, ChatState>(
          builder: (context, chatState) {
            if (chatState.currentSession == null) {
              return const Center(child: Text('Select or start a new chat'));
            }

            final messages = chatState.currentSession!.messages;
            final totalSystemCost = chatState.sessions.fold<double>(
              0, (sum, s) => sum + s.messages.fold<double>(0, (sumM, m) => sumM + (m.estimatedCost ?? 0))
            );

            bool isNearLimit = settingsState.budgetLimit > 0 && 
                               totalSystemCost >= (settingsState.budgetLimit * 0.85);
            bool isOverLimit = settingsState.budgetLimit > 0 && 
                               totalSystemCost >= settingsState.budgetLimit;
            bool isBlocked = isOverLimit && settingsState.blockOnLimit;

            return Column(
              children: [
                if (isNearLimit)
                  Container(
                    width: double.infinity,
                    color: isOverLimit ? Colors.red.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(isOverLimit ? LucideIcons.alertOctagon : LucideIcons.alertTriangle, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isOverLimit 
                              ? 'Budget limit exceeded! (\$${totalSystemCost.toStringAsFixed(4)} / \$${settingsState.budgetLimit})'
                              : 'Approaching budget limit! (\$${totalSystemCost.toStringAsFixed(4)} / \$${settingsState.budgetLimit})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: messages.length + (chatState.isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const _MessageBubble(
                          content: '',
                          role: 'assistant',
                          isStreaming: true,
                        );
                      }
                      final msg = messages[index];
                      return _MessageBubble(
                        content: msg.content,
                        role: msg.role,
                        tokens: msg.estimatedTokens,
                        cost: msg.estimatedCost,
                      );
                    },
                  ),
                ),
                if (isBlocked)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Input blocked: Budget limit reached.',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  _buildInputArea(context, chatState),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, ChatState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                context.read<ChatBloc>().add(SendMessage(
                  content: value,
                  providerId: state.currentSession!.selectedProvider,
                  model: state.currentSession!.selectedModel,
                ));
                _textController.clear();
              },
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.send),
            onPressed: () {
              if (_textController.text.trim().isEmpty) return;
              context.read<ChatBloc>().add(SendMessage(
                content: _textController.text,
                providerId: state.currentSession!.selectedProvider,
                model: state.currentSession!.selectedModel,
              ));
              _textController.clear();
            },
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final String role;
  final bool isStreaming;
  final int? tokens;
  final double? cost;

  const _MessageBubble({
    required this.content,
    required this.role,
    this.isStreaming = false,
    this.tokens,
    this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isUser ? Colors.blue : Colors.teal,
            child: Icon(isUser ? LucideIcons.user : LucideIcons.bot, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isUser ? 'You' : 'Gladden',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (tokens != null && cost != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· $tokens tokens (\$${cost!.toStringAsFixed(6)})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (isStreaming && content.isEmpty)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thinking...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else
                  MarkdownBody(
                    data: content + (isStreaming ? ' █' : ''),
                    selectable: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
