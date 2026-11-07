import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_controller.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'artwork.dart';

/// The live play queue: tap to jump, drag to reorder, swipe to remove.
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _QueueBody(scroll: scroll),
    ),
  );
}

class _QueueBody extends StatelessWidget {
  final ScrollController scroll;
  const _QueueBody({required this.scroll});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerController>();
    final queue = p.queue;
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.pagePad, 18, Sp.pagePad, 8),
          child: Row(children: [
            Expanded(child: Text('Queue', style: RyFonts.ui(26, weight: FontWeight.w800, color: Colors.white))),
            if (queue.length > 1) TextButton(onPressed: p.clearUpcoming, child: const Text('Clear')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.pagePad, 0, Sp.pagePad, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${queue.length} ${queue.length == 1 ? 'song' : 'songs'}${p.shuffle ? ' · shuffled' : ''}',
              style: RyFonts.ui(TypeScale.md, color: Colors.white54),
            ),
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? Center(child: Text('Nothing queued', style: RyFonts.ui(TypeScale.md, color: Colors.white54)))
              : ReorderableListView.builder(
                  scrollController: scroll,
                  buildDefaultDragHandles: false,
                  itemCount: queue.length,
                  onReorder: p.moveInQueue,
                  itemBuilder: (_, i) {
                    final s = queue[i];
                    final current = i == p.index;
                    final row = ListTile(
                      key: ValueKey('q$i-${s.videoId}'),
                      onTap: () => p.playIndex(i),
                      leading: Artwork(url: s.thumbnail, size: 48),
                      title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(16, weight: FontWeight.w500, color: current ? Theme.of(context).colorScheme.primary : Colors.white)),
                      subtitle: Text(s.artists, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(TypeScale.md, color: Colors.white54)),
                      trailing: current
                          ? Icon(Icons.graphic_eq_rounded, color: Theme.of(context).colorScheme.primary)
                          : ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle_rounded, color: Colors.white38)),
                    );
                    if (current) return row;
                    return Dismissible(
                      key: ValueKey('dq$i-${s.videoId}'),
                      direction: DismissDirection.endToStart,
                      background: Container(color: Colors.red.shade700, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), child: const Icon(Icons.delete_outline_rounded, color: Colors.white)),
                      onDismissed: (_) => p.removeFromQueue(i),
                      child: row,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
