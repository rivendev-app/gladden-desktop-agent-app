import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/settings_bloc.dart';
import '../usage/usage_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Storage Error: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state.isLoading) return const Center(child: CircularProgressIndicator());
  
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                _buildSectionHeader(context, 'API Configuration'),
                _buildProviderCard(context, 'OpenAI', 'openai', state.apiKeys['openai'], LucideIcons.bot),
                const SizedBox(height: 16),
                _buildProviderCard(context, 'Google Gemini', 'gemini', state.apiKeys['gemini'], LucideIcons.sparkles),
                
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Usage & Limits'),
                _buildBudgetCard(context, state),
                
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Data Management'),
                _buildUsageHistoryCard(context),
  
                const SizedBox(height: 48),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                _buildAboutSection(context),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildProviderCard(BuildContext context, String name, String id, String? currentKey, IconData icon) {
    return _ProviderCard(
      name: name,
      id: id,
      currentKey: currentKey,
      icon: icon,
    );
  }

  Widget _buildBudgetCard(BuildContext context, SettingsState state) {
    final controller = TextEditingController(text: state.budgetLimit.toString());
    
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wallet, size: 20, color: Colors.blueAccent),
              const SizedBox(width: 12),
              const Text('Monthly Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Limit (USD)',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixText: '\$ ',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final limit = double.tryParse(controller.text) ?? 0.0;
                  context.read<SettingsBloc>().add(UpdateBudget(
                    limit: limit, 
                    block: state.blockOnLimit,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Update'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hard Limit Enforcement', style: TextStyle(fontSize: 14)),
            subtitle: Text('Block new messages when budget is exceeded', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            value: state.blockOnLimit,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              context.read<SettingsBloc>().add(UpdateBudget(
                limit: state.budgetLimit, 
                block: val,
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsageHistoryCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UsageHistoryScreen()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.barChart2, color: Colors.purpleAccent),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Usage History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('View detailed cost and token analytics', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(LucideIcons.chevronRight, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF252525),
            ],
        ),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/svg/gladden.svg',
            height: 32,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(height: 16),
          Text(
            'Open Source Custom Desktop Agent',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLinkButton(context, 'GitHub', LucideIcons.github, 'https://github.com/rivendev-app/gladden-desktop-agent-app'),
              const SizedBox(width: 16),
              _buildLinkButton(context, 'Website', LucideIcons.globe, 'https://rivendev.app'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'v1.0.0 • Built with Flutter',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, String label, IconData icon, String url) {
    return TextButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      icon: Icon(icon, size: 16, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white70)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    );
  }
}

class _ProviderCard extends StatefulWidget {
  final String name;
  final String id;
  final String? currentKey;
  final IconData icon;

  const _ProviderCard({
    required this.name,
    required this.id,
    required this.currentKey,
    required this.icon,
  });

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  late final TextEditingController _controller;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentKey);
  }

  @override
  void didUpdateWidget(_ProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentKey != oldWidget.currentKey && 
        widget.currentKey != _controller.text) {
      _controller.text = widget.currentKey ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = widget.currentKey != null && widget.currentKey!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 20, color: hasKey ? const Color(0xFFC5A059) : Colors.grey),
              const SizedBox(width: 12),
              Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (hasKey)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFC5A059).withOpacity(0.3)),
                  ),
                  child: const Text('Configured', style: TextStyle(color: Color(0xFFC5A059), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter API Key',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 16, color: Colors.grey),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  obscureText: _isObscure,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    context.read<SettingsBloc>().add(SaveApiKey(widget.id, _controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved ${widget.name} key'), duration: const Duration(seconds: 2)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save'),
              ),
              if (hasKey) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                  onPressed: () {
                    context.read<SettingsBloc>().add(DeleteApiKey(widget.id));
                    _controller.clear();
                  },
                  tooltip: 'Remove Key',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
