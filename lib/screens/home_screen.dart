import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/editor_provider.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Column(children: [
        _TopBar(onNew: _newProject),
        _TabBar(controller: _tabs),
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            _ProjectsTab(onOpen: _openProject, onNew: _newProject),
            const _TemplatesTab(),
            const _SettingsTab(),
          ]),
        ),
      ]),
    );
  }

  void _newProject() {
    showDialog(context: context, builder: (_) => _NewProjectDialog(
      onCreate: (title, desc) => _createAndOpen(title, desc),
    ));
  }

  void _createAndOpen(String title, String desc) {
    final editor = context.read<EditorProvider>();
    editor.createNewProject(title: title, description: desc);
    if (editor.project != null) {
      context.read<ProjectProvider>().saveProject(editor.project!);
      _openEditor();
    }
  }

  void _openProject(ChessProject project) {
    context.read<EditorProvider>().loadProject(project);
    _openEditor();
  }

  void _openEditor() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const EditorScreen(),
        transitionsBuilder: (_, a1, a2, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a1, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onNew;
  const _TopBar({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Icon(Icons.extension, color: AppTheme.accent, size: 20),
        ),
        const SizedBox(width: 12),
        const Text('ChessMotion',
            style: TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const Spacer(),
        _IconBtn(icon: Icons.search, onTap: () {}),
        const SizedBox(width: 4),
        _IconBtn(icon: Icons.notifications_none, onTap: () {}),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onNew,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.add, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('New', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, color: AppTheme.textSecondary, size: 22),
    padding: const EdgeInsets.all(6),
    constraints: const BoxConstraints(),
  );
}

// ── Tab Bar ────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.bgCard,
    child: TabBar(
      controller: controller,
      indicatorColor: AppTheme.accent,
      indicatorWeight: 2.5,
      labelColor: Colors.white,
      unselectedLabelColor: AppTheme.textSecondary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      tabs: const [
        Tab(text: 'Projects'),
        Tab(text: 'Templates'),
        Tab(text: 'Settings'),
      ],
    ),
  );
}

// ── Projects Tab ───────────────────────────────────────────────────────────
class _ProjectsTab extends StatelessWidget {
  final Function(ChessProject) onOpen;
  final VoidCallback onNew;
  const _ProjectsTab({required this.onOpen, required this.onNew});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final projects = provider.sortedProjects;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (projects.isEmpty) {
      return _EmptyState(onNew: onNew);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsRow(count: projects.length),
        const SizedBox(height: 16),
        ...projects.map((p) => _ProjectCard(
          project: p,
          onOpen: () => onOpen(p),
          onDelete: () => provider.deleteProject(p.id),
          onDuplicate: () => provider.duplicateProject(p.id),
        )),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int count;
  const _StatsRow({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: AppTheme.cardDecoration,
    child: Row(children: [
      _StatItem(label: 'Projects', value: '$count'),
      _divider(),
      _StatItem(label: 'Edited', value: 'Today'),
      _divider(),
      _StatItem(label: 'Exports', value: '0'),
    ]),
  );

  Widget _divider() => Container(
    width: 1, height: 30,
    color: AppTheme.border,
    margin: const EdgeInsets.symmetric(horizontal: 20),
  );
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ],
  );
}

class _ProjectCard extends StatelessWidget {
  final ChessProject project;
  final VoidCallback onOpen, onDelete, onDuplicate;
  const _ProjectCard({
    required this.project,
    required this.onOpen,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Thumbnail
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.extension,
                    color: AppTheme.accent, size: 32),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.title, style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _Badge(text: project.settings.aspectRatioLabel),
                    const SizedBox(width: 6),
                    _Badge(text: project.formattedDuration),
                    const SizedBox(width: 6),
                    _Badge(text: '${project.layers.length} layers'),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(project.updatedAt),
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 11),
                  ),
                ],
              )),
              // Menu
              PopupMenuButton<String>(
                color: AppTheme.bgSurface,
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                onSelected: (v) {
                  if (v == 'open') onOpen();
                  if (v == 'duplicate') onDuplicate();
                  if (v == 'delete') _confirmDelete(context);
                },
                itemBuilder: (_) => [
                  _menuItem('open', 'Open', Icons.folder_open),
                  _menuItem('duplicate', 'Duplicate', Icons.copy),
                  _menuItem('delete', 'Delete', Icons.delete_outline,
                      color: AppTheme.accentRed),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      title: const Text('Delete Project', style: TextStyle(color: Colors.white)),
      content: Text('Delete "${project.title}"? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
        TextButton(onPressed: () { Navigator.pop(context); onDelete(); },
            child: const Text('Delete', style: TextStyle(color: AppTheme.accentRed))),
      ],
    ));
  }

  PopupMenuItem<String> _menuItem(String value, String label, IconData icon,
      {Color? color}) =>
      PopupMenuItem<String>(
        value: value,
        child: Row(children: [
          Icon(icon, color: color ?? AppTheme.textSecondary, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 13)),
        ]),
      );

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.bgSurface,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(text, style: const TextStyle(
        color: AppTheme.textSecondary, fontSize: 10)),
  );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        child: const Icon(Icons.video_library_outlined,
            color: AppTheme.textSecondary, size: 40),
      ),
      const SizedBox(height: 20),
      const Text('No Projects Yet', style: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Create your first chess video project',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: onNew,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Create New Project'),
      ),
    ]),
  );
}

// ── Templates Tab ──────────────────────────────────────────────────────────
class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context) {
    final templates = [
      ('Chess Opening', Icons.grid_4x4, 'Sicilian, French, Caro-Kann', AppTheme.primary),
      ('Highlight Reel', Icons.auto_awesome, 'Best moves montage', AppTheme.accentRed),
      ('Tutorial Video', Icons.school_outlined, 'Step by step guide', AppTheme.accentCyan),
      ('Game Analysis', Icons.analytics_outlined, 'Full game breakdown', AppTheme.accent),
      ('Puzzle Reveal', Icons.extension, 'Tactical puzzles', Color(0xFF6A1B9A)),
      ('Championship', Icons.emoji_events, 'Tournament highlights', Color(0xFFE65100)),
    ];

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: templates.map((t) => _TemplateCard(
        title: t.$1, icon: t.$2, subtitle: t.$3, color: t.$4,
      )).toList(),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  const _TemplateCard({required this.title, required this.icon,
    required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Settings Tab ───────────────────────────────────────────────────────────
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _SettingsSection(title: 'App', items: [
        _SettingItem(icon: Icons.dark_mode, label: 'Theme', value: 'Dark'),
        _SettingItem(icon: Icons.language, label: 'Language', value: 'English'),
        _SettingItem(icon: Icons.storage, label: 'Cache', value: 'Clear'),
      ]),
      const SizedBox(height: 16),
      _SettingsSection(title: 'Editor', items: [
        _SettingItem(icon: Icons.grid_on, label: 'Show Grid', value: 'On'),
        _SettingItem(icon: Icons.near_me, label: 'Snap to Grid', value: 'On'),
        _SettingItem(icon: Icons.history, label: 'Undo History', value: '50'),
      ]),
      const SizedBox(height: 16),
      _SettingsSection(title: 'Export', items: [
        _SettingItem(icon: Icons.video_settings, label: 'Default FPS', value: '30'),
        _SettingItem(icon: Icons.hd, label: 'Default Quality', value: '1080p'),
      ]),
      const SizedBox(height: 16),
      _SettingsSection(title: 'About', items: [
        _SettingItem(icon: Icons.info_outline, label: 'Version', value: '1.0.0'),
        _SettingItem(icon: Icons.policy_outlined, label: 'Privacy Policy', value: ''),
        _SettingItem(icon: Icons.star_border, label: 'Rate App', value: ''),
      ]),
    ]);
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingItem> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(
          color: AppTheme.textSecondary, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ),
      Container(
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: items.asMap().entries.map((e) => Column(
            children: [
              e.value,
              if (e.key < items.length - 1) const Divider(
                  height: 1, color: AppTheme.divider, indent: 48),
            ],
          )).toList(),
        ),
      ),
    ],
  );
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SettingItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(icon, color: AppTheme.textSecondary, size: 20),
    title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
    trailing: value.isEmpty
        ? const Icon(Icons.chevron_right, color: AppTheme.textHint)
        : Text(value, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13)),
    onTap: () {},
  );
}

// ── New Project Dialog ─────────────────────────────────────────────────────
class _NewProjectDialog extends StatefulWidget {
  final Function(String, String) onCreate;
  const _NewProjectDialog({required this.onCreate});
  @override State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _titleCtrl = TextEditingController(text: 'My Chess Video');
  final _descCtrl  = TextEditingController();

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppTheme.bgCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.add_box_outlined, color: AppTheme.accent, size: 22),
          const SizedBox(width: 10),
          const Text('New Project', style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 20),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Project Title'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Description (optional)'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              widget.onCreate(_titleCtrl.text.trim(), _descCtrl.text.trim());
            },
            child: const Text('Create Project'),
          ),
        ),
      ]),
    ),
  );
}
