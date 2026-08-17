import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';

final manualsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiProvider);
  final res = await api.get('/products');
  return res.data;
});

class BrowseManualsScreen extends ConsumerStatefulWidget {
  final String? shopId;
  const BrowseManualsScreen({super.key, this.shopId});

  @override
  ConsumerState<BrowseManualsScreen> createState() => _BrowseManualsScreenState();
}

class _BrowseManualsScreenState extends ConsumerState<BrowseManualsScreen> {
  String searchQuery = '';
  String? selectedBranch;
  String? selectedCourse;

  final branches = ['Computer Science', 'Mechanical', 'Civil', 'Electrical', 'Electronics', 'Chemical'];
  final courseTypes = ['Engineering', 'Polytechnic', 'Diploma', 'ITI'];

  @override
  Widget build(BuildContext context) {
    final manualsAsync = ref.watch(manualsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Browse Manuals'),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: TextField(
                          onChanged: (val) => setState(() => searchQuery = val),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(
                            hintText: 'Search title or subject...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterDropdown(
                              hint: 'Branch',
                              value: selectedBranch,
                              items: branches,
                              onChanged: (val) => setState(() => selectedBranch = val),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterDropdown(
                              hint: 'Course Type',
                              value: selectedCourse,
                              items: courseTypes,
                              onChanged: (val) => setState(() => selectedCourse = val),
                            ),
                            if (selectedBranch != null || selectedCourse != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () => setState(() {
                                    selectedBranch = null;
                                    selectedCourse = null;
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: manualsAsync.when(
                    data: (manuals) {
                      final filtered = manuals.where((m) {
                        final titleMatch = m['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) || 
                                           (m['subject'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
                        final branchMatch = selectedBranch == null || m['branch'] == selectedBranch;
                        final courseMatch = selectedCourse == null || m['course_type'] == selectedCourse;
                        final shopMatch = widget.shopId == null || m['shop_id'].toString() == widget.shopId;
                        return titleMatch && branchMatch && courseMatch && shopMatch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('No manuals found.'));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final manual = filtered[index];
                          final stock = manual['stock_count'] as int;
                          final isOutOfStock = stock <= 0;

                          return GestureDetector(
                            onTap: () {
                              context.push('/manual-detail', extra: manual);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            image: manual['cover_photo_url'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(manual['cover_photo_url']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                            color: theme.colorScheme.surfaceContainerHighest,
                                          ),
                                          child: manual['cover_photo_url'] == null
                                            ? const Icon(Icons.book, size: 48, color: Colors.grey)
                                            : null,
                                        ),
                                        if (isOutOfStock)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.6),
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Out of Stock',
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          )
                                        else if (stock <= 5)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Only $stock left',
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          manual['title'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          manual['branch'],
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '₹${manual['price']}',
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value != null ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: value != null ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          dropdownColor: const Color(0xFF1E293B),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
