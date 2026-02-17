import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../blocs/usage_bloc.dart';

class UsageHistoryScreen extends StatelessWidget {
  const UsageHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage History & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => context.read<UsageBloc>().add(LoadUsage()),
          ),
        ],
      ),
      body: BlocBuilder<UsageBloc, UsageState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
          if (state.error != null) return Center(child: Text('Error: ${state.error}'));

          final totalCost = state.costByProvider.values.fold<double>(0, (sum, val) => sum + val);
          final totalTokens = state.items.fold<int>(0, (sum, m) => sum + (m.estimatedTokens ?? 0));

          return Column(
            children: [
              _buildFilterBar(context, state),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSummaryCards(context, totalCost, totalTokens, state.items.length),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildPieChart(context, 'Cost by Provider', state.costByProvider)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildPieChart(context, 'Cost by Model', state.costByModel)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildBarChart(context, 'Daily Cost (USD)', state.dailyCost),
                    const SizedBox(height: 32),
                    _buildHistoryList(context, state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, UsageState state) {
    final dateLabel = state.start != null && state.end != null
        ? '${DateFormat('MMM d').format(state.start!)} - ${DateFormat('MMM d').format(state.end!)}'
        : 'All Time';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          const Icon(LucideIcons.filter, size: 16),
          const SizedBox(width: 12),
          _FilterChip(
            label: dateLabel,
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange: state.start != null && state.end != null
                    ? DateTimeRange(start: state.start!, end: state.end!)
                    : null,
              );
              if (range != null) {
                context.read<UsageBloc>().add(LoadUsage(
                      start: range.start,
                      end: range.end,
                      provider: state.provider,
                      model: state.model,
                    ));
              }
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Filter by Provider',
            initialValue: state.provider,
            onSelected: (val) {
              context.read<UsageBloc>().add(LoadUsage(
                    start: state.start,
                    end: state.end,
                    provider: val == 'all' ? null : val,
                    model: state.model,
                  ));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Providers')),
              const PopupMenuItem(value: 'openai', child: Text('OpenAI')),
              const PopupMenuItem(value: 'gemini', child: Text('Gemini')),
            ],
            child: _FilterChip(
              label: state.provider?.toUpperCase() ?? 'All Providers',
              onTap: () {}, // Handled by PopupMenuButton
            ),
          ),
          if (state.start != null || state.provider != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.xCircle, size: 16),
              tooltip: 'Clear Filters',
              onPressed: () => context.read<UsageBloc>().add(LoadUsage()),
            ),
          ],
          const Spacer(),
          Text(
            '${state.items.length} items found',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, double totalCost, int totalTokens, int totalMessages) {
    return Row(
      children: [
        _Card(
          title: 'Total Estimated Cost',
          value: '\$${totalCost.toStringAsFixed(4)}',
          icon: LucideIcons.dollarSign,
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _Card(
          title: 'Total Tokens',
          value: totalTokens.toString(),
          icon: LucideIcons.cpu,
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        _Card(
          title: 'Total Messages',
          value: totalMessages.toString(),
          icon: LucideIcons.messageSquare,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildPieChart(BuildContext context, String title, Map<String, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    final total = data.values.fold<double>(0, (sum, val) => sum + val);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            Column(
              children: data.entries.map((e) {
                final index = data.keys.toList().indexOf(e.key) % colors.length;
                final percentage = (e.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, color: colors[index]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
                      Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Custom simplified "progress bar" style breakdown
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: data.entries.map((e) {
                    final index = data.keys.toList().indexOf(e.key) % colors.length;
                    return Expanded(
                      flex: (e.value * 100).toInt(),
                      child: Container(color: colors[index]),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, String title, Map<String, double> dailyData) {
    if (dailyData.isEmpty) return const SizedBox.shrink();

    final sortedKeys = dailyData.keys.toList()..sort();
    final maxCost = dailyData.values.fold<double>(0, (max, val) => val > max ? val : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: sortedKeys.map((date) {
                  final cost = dailyData[date]!;
                  final heightFactor = maxCost > 0 ? cost / maxCost : 0.0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 20,
                        height: 100 * heightFactor,
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(date.substring(8), style: const TextStyle(fontSize: 10)), // Day only
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, UsageState state) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Detailed Log', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = state.items[index];
              return ListTile(
                title: Text(m.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${m.session.target?.selectedProvider} · ${m.session.target?.selectedModel} · ${DateFormat('MMM d, HH:mm').format(m.timestamp)}'),
                trailing: Text('\$${(m.estimatedCost ?? 0).toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _Card({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
