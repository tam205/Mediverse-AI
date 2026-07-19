import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/utils/firebase_error_messages.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import 'models/history_record.dart';
import 'services/history_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.inShell = false});

  final bool inShell;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = const HistoryRepository();
  late Future<List<HistoryRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _repository.getHistory();
  }

  Future<void> _refresh() async {
    setState(() => _historyFuture = _repository.getHistory());
    await _historyFuture;
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HistoryRecord>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final hasError = snapshot.hasError;
            final records = snapshot.data ?? const <HistoryRecord>[];
            return ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                widget.inShell ? 22 : 18,
                18,
                widget.inShell ? 110 : 28,
              ),
              children: [
                if (widget.inShell)
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                const SizedBox(height: 12),
                const _SegmentedFilter(),
                const SizedBox(height: 16),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (hasError)
                  _HistoryErrorState(
                    message: friendlyHistoryMessage(snapshot.error!),
                    onRetry: () {
                      setState(() => _historyFuture = _repository.getHistory());
                    },
                  )
                else if (records.isEmpty)
                  const _EmptyHistoryState()
                else
                  ...records.map(
                    (record) => _HistoryTile(
                      title: record.title,
                      status: record.status,
                      color: record.color,
                      icon: record.icon,
                    ),
                  ),
                if (!loading && !hasError && records.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Clear History'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );

    if (widget.inShell) return Scaffold(body: body);
    return Scaffold(
      appBar: const MediverseAppBar(title: 'History'),
      body: body,
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: AppColors.amber,
          ),
          const SizedBox(height: 16),
          const Text(
            'Could not load history',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.history_outlined, size: 64, color: AppColors.muted),
          SizedBox(height: 16),
          Text(
            'No history yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Your medicine safety checks, scans, and conversations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SegmentedFilter extends StatelessWidget {
  const _SegmentedFilter();

  @override
  Widget build(BuildContext context) {
    final items = ['All', 'Interactions', 'Scans', 'Chats'];
    return Row(
      children: items.map((item) {
        final selected = item == 'All';
        return Expanded(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.ocean : AppColors.border,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: selected ? AppColors.ocean : AppColors.muted,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.title,
    required this.status,
    required this.color,
    required this.icon,
  });

  final String title;
  final String status;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
