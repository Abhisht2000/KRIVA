import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_providers.dart';
import '../../models/broadcast_model.dart';
import '../../models/domain_model.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.primary, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Admin Panel',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Members'),
                Tab(text: 'Broadcast'),
                Tab(text: 'Roadmaps'),
                Tab(text: 'Analytics'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _MembersTab(),
                  _BroadcastTab(),
                  _RoadmapEditorTab(),
                  _AnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Members Tab ──────────────────────────────────────────────────────────────
class _MembersTab extends ConsumerWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(_membersStreamProvider);

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return const Center(child: Text('No members found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final m = members[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundImage:
                      m.photoUrl.isNotEmpty ? NetworkImage(m.photoUrl) : null,
                  backgroundColor: AppColors.surfaceLight,
                  child: m.photoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${m.clubId} · ${m.batch}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor(m.role).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    m.role.name.toUpperCase(),
                    style: TextStyle(
                      color: _roleColor(m.role),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.admin => AppColors.error,
      UserRole.lead => AppColors.accent,
      UserRole.member => AppColors.secondary,
    };
  }
}

final _membersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getMembers();
});

// ── Broadcast Tab ──────────────────────────────────────────────────────────────
class _BroadcastTab extends ConsumerStatefulWidget {
  const _BroadcastTab();

  @override
  ConsumerState<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends ConsumerState<_BroadcastTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audienceType = 'all';
  String _audienceValue = '';
  bool _isSending = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final user = ref.read(currentUserProvider);
    final bc = BroadcastModel(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      audienceType: _audienceType,
      audienceValue: _audienceValue,
      sentBy: user?.name ?? 'Admin',
      sentAt: DateTime.now(),
      readBy: [],
    );

    try {
      await ref.read(databaseRepositoryProvider).createBroadcast(bc);
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Compose Broadcast',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title_rounded, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.message_outlined, size: 20),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text('Target Audience',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    )),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All'), icon: Icon(Icons.groups)),
                ButtonSegment(
                    value: 'domain',
                    label: Text('Domain'),
                    icon: Icon(Icons.map_outlined)),
                ButtonSegment(
                    value: 'batch',
                    label: Text('Batch'),
                    icon: Icon(Icons.school_outlined)),
              ],
              selected: {_audienceType},
              onSelectionChanged: (sel) =>
                  setState(() => _audienceType = sel.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary.withValues(alpha: 0.2);
                  }
                  return AppColors.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return AppColors.textMuted;
                }),
              ),
            ),
            if (_audienceType != 'all') ...[
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: _audienceType == 'domain' ? 'Domain ID (e.g. dsa)' : 'Batch (e.g. Batch of 2026)',
                  prefixIcon: const Icon(Icons.filter_list_rounded, size: 20),
                ),
                onChanged: (v) => _audienceValue = v.trim(),
              ),
            ],
            const SizedBox(height: 28),
            _isSending
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sendBroadcast,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Roadmap Editor Tab ──────────────────────────────────────────────────────
class _RoadmapEditorTab extends ConsumerStatefulWidget {
  const _RoadmapEditorTab();

  @override
  ConsumerState<_RoadmapEditorTab> createState() => _RoadmapEditorTabState();
}

class _RoadmapEditorTabState extends ConsumerState<_RoadmapEditorTab> {
  final _domainIdCtrl = TextEditingController();
  final _domainNameCtrl = TextEditingController();
  final _domainDescCtrl = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _domainIdCtrl.dispose();
    _domainNameCtrl.dispose();
    _domainDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _createDomain() async {
    if (_domainIdCtrl.text.isEmpty || _domainNameCtrl.text.isEmpty) return;
    setState(() => _isCreating = true);

    final user = ref.read(currentUserProvider);
    final domain = DomainModel(
      id: _domainIdCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
      name: _domainNameCtrl.text.trim(),
      description: _domainDescCtrl.text.trim(),
      leadUserId: user?.uid ?? '',
      modules: [],
    );

    try {
      await ref.read(databaseRepositoryProvider).createDomain(domain);
      _domainIdCtrl.clear();
      _domainNameCtrl.clear();
      _domainDescCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Domain created!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainsAsync = ref.watch(domainsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create New Domain',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _domainIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Domain ID (slug)',
              hintText: 'e.g. cyber_security',
              prefixIcon: Icon(Icons.key_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _domainNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Domain Name',
              hintText: 'e.g. Cyber Security',
              prefixIcon: Icon(Icons.label_outline, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _domainDescCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Icon(Icons.description_outlined, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _isCreating
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _createDomain,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Create Domain'),
                ),
          const SizedBox(height: 28),
          Text('Existing Domains',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          domainsAsync.when(
            data: (domains) => Column(
              children: domains
                  .map((d) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(d.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(d.id,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted),
                        ),
                      ))
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

// ── Analytics Tab ────────────────────────────────────────────────────────────
class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(_membersStreamProvider);
    final domainsAsync = ref.watch(domainsProvider);

    return membersAsync.when(
      data: (members) {
        final totalMembers = members.length;
        final totalStreak = members.fold(0, (sum, m) => sum + m.streak.count);
        final averageStreak = totalMembers > 0 ? (totalStreak / totalMembers).toStringAsFixed(1) : '0';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary cards row
              Row(
                children: [
                  Expanded(
                    child: _AnalyticsCard(
                      title: 'Total Members',
                      value: '$totalMembers',
                      icon: Icons.groups_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsCard(
                      title: 'Avg. Streak',
                      value: '$averageStreak days',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weekly active engagement line chart
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Active Members',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Active logins and activities logged over past 7 days.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: CustomPaint(
                        size: const Size(double.infinity, 120),
                        painter: _LineChartPainter(
                          points: const [12, 18, 15, 24, 28, 20, 32],
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Mon', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text('Tue', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text('Wed', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text('Thu', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text('Fri', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text('Sat', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text('Sun', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Domain Popularity Bar Chart
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enrolled Members per Domain',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    domainsAsync.when(
                      data: (domains) {
                        // Aggregate enrolments
                        final domainCounts = <String, int>{};
                        for (final m in members) {
                          for (final d in m.domainsFollowing) {
                            domainCounts[d] = (domainCounts[d] ?? 0) + 1;
                          }
                        }

                        final labels = domains.map((d) => d.name.split(' ').first).toList();
                        final values = domains.map((d) => (domainCounts[d.id] ?? 0).toDouble()).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 120,
                              child: CustomPaint(
                                size: const Size(double.infinity, 120),
                                painter: _BarChartPainter(
                                  values: values,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: labels
                                  .map((lbl) => Text(
                                        lbl,
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ))
                                  .toList(),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading members stats: $e')),
    );
  }
}

// ── Analytics Summary Card Widget ───────────────────────────────────────────
class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painters for Analytics Charts ────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _LineChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final widthStep = size.width / (points.length - 1);

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i * widthStep;
      final y = size.height - (points[i] / maxVal) * (size.height - 10);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Outer glow effect
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);

    // Draw active node points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final x = i * widthStep;
      final y = size.height - (points[i] / maxVal) * (size.height - 10);
      canvas.drawCircle(Offset(x, y), 4.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _BarChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final maxVal = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    final totalBars = values.length;
    final spacing = size.width * 0.15;
    final totalSpacing = spacing * (totalBars + 1);
    final barWidth = (size.width - totalSpacing) / totalBars;

    for (int i = 0; i < totalBars; i++) {
      final x = spacing + i * (barWidth + spacing);
      final height = maxVal > 0 ? (values[i] / maxVal) * (size.height - 10) : 0.0;
      final y = size.height - height;

      // Draw rounded bar
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, height),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
