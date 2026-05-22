import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import '../models/layer_model.dart';
import '../models/keyframe_model.dart';
import '../theme/app_theme.dart';

class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({super.key});
  @override State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    final layer  = editor.selectedLayer;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgPanel,
        border: Border(left: BorderSide(color: AppTheme.border)),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.bgCard,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(children: [
            const Icon(Icons.tune, color: AppTheme.accent, size: 16),
            const SizedBox(width: 8),
            Text(
              layer != null ? layer.name : 'Properties',
              style: const TextStyle(color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ]),
        ),

        if (layer == null) ...[
          const Expanded(child: _NoSelection()),
        ] else ...[
          // Tabs
          TabBar(
            controller: _tabs,
            indicatorColor: AppTheme.accent,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            tabs: const [Tab(text: 'Transform'), Tab(text: 'Effects'), Tab(text: 'Keyframes')],
          ),
          Expanded(child: TabBarView(controller: _tabs, children: [
            _TransformTab(layer: layer, editor: editor),
            _EffectsTab(layer: layer, editor: editor),
            _KeyframesTab(layer: layer, editor: editor),
          ])),
        ],
      ]),
    );
  }
}

// ── No Selection ───────────────────────────────────────────────────────────
class _NoSelection extends StatelessWidget {
  const _NoSelection();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.touch_app_outlined, color: AppTheme.textHint, size: 36),
      const SizedBox(height: 12),
      const Text('Select a layer', style: TextStyle(
          color: AppTheme.textSecondary, fontSize: 13)),
      const SizedBox(height: 4),
      const Text('to edit properties',
          style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
    ]),
  );
}

// ── Transform Tab ──────────────────────────────────────────────────────────
class _TransformTab extends StatelessWidget {
  final EditorLayer layer;
  final EditorProvider editor;
  const _TransformTab({required this.layer, required this.editor});

  @override
  Widget build(BuildContext context) {
    final t = layer.transform;
    return ListView(padding: const EdgeInsets.all(12), children: [
      _PropSlider(label: 'Opacity', value: t.opacity * 100,
        min: 0, max: 100, suffix: '%',
        onChanged: (v) => editor.updateLayerTransform(
            layer.id, t.copyWith(opacity: v / 100))),
      _PropSlider(label: 'Scale', value: t.scaleX * 100,
        min: 0, max: 500, suffix: '%',
        onChanged: (v) => editor.updateLayerTransform(
            layer.id, t.copyWith(scaleX: v / 100, scaleY: v / 100))),
      _PropSlider(label: 'Rotation', value: t.rotation,
        min: -360, max: 360, suffix: '°',
        onChanged: (v) => editor.updateLayerTransform(
            layer.id, t.copyWith(rotation: v))),
      _SectionLabel(label: 'Position'),
      _PropSlider(label: 'X', value: t.x,
        min: -1000, max: 1000, suffix: 'px',
        onChanged: (v) => editor.updateLayerTransform(
            layer.id, t.copyWith(x: v))),
      _PropSlider(label: 'Y', value: t.y,
        min: -1000, max: 1000, suffix: 'px',
        onChanged: (v) => editor.updateLayerTransform(
            layer.id, t.copyWith(y: v))),
      _SectionLabel(label: 'Skew'),
      _PropSlider(label: 'Skew X', value: t.skewX,
        min: -45, max: 45, suffix: '°',
        onChanged: (v) => editor.updateLayerTransform(
            layer.id, t.copyWith(skewX: v))),
      _PropSlider(label: 'Skew Y', value: t.skewY,
        min: -45, max: 45, suffix: '°',
        onChanged: (v) => editor.updateLayerTransform(
            layer.id, t.copyWith(skewY: v))),
      const SizedBox(height: 8),
      _ResetBtn(onTap: () => editor.updateLayerTransform(
          layer.id, LayerTransform())),
    ]);
  }
}

// ── Effects Tab ────────────────────────────────────────────────────────────
class _EffectsTab extends StatelessWidget {
  final EditorLayer layer;
  final EditorProvider editor;
  const _EffectsTab({required this.layer, required this.editor});

  @override
  Widget build(BuildContext context) {
    final e = layer.effect;
    return ListView(padding: const EdgeInsets.all(12), children: [
      _SectionLabel(label: 'Color Correction'),
      _PropSlider(label: 'Brightness', value: e.brightness,
        min: -100, max: 100, suffix: '',
        onChanged: (v) => editor.updateLayerEffect(
            layer.id, e.copyWith(brightness: v))),
      _PropSlider(label: 'Contrast', value: e.contrast,
        min: -100, max: 100, suffix: '',
        onChanged: (v) => editor.updateLayerEffect(
            layer.id, e.copyWith(contrast: v))),
      _PropSlider(label: 'Saturation', value: e.saturation,
        min: -100, max: 100, suffix: '',
        onChanged: (v) => editor.updateLayerEffect(
            layer.id, e.copyWith(saturation: v))),
      _PropSlider(label: 'Hue', value: e.hue,
        min: -180, max: 180, suffix: '°',
        onChanged: (v) => editor.updateLayerEffect(
            layer.id, e.copyWith(hue: v))),
      _SectionLabel(label: 'Filters'),
      _PropSlider(label: 'Blur', value: e.blur,
        min: 0, max: 50, suffix: 'px',
        onChanged: (v) => editor.updateLayerEffect(
            layer.id, e.copyWith(blur: v))),
      const SizedBox(height: 8),
      _ResetBtn(onTap: () => editor.updateLayerEffect(layer.id, LayerEffect())),
    ]);
  }
}

// ── Keyframes Tab ──────────────────────────────────────────────────────────
class _KeyframesTab extends StatelessWidget {
  final EditorLayer layer;
  final EditorProvider editor;
  const _KeyframesTab({required this.layer, required this.editor});

  @override
  Widget build(BuildContext context) {
    final kfs = layer.keyframes;
    return Column(children: [
      // Add keyframe area
      Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.divider)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Keyframe', style: TextStyle(
              color: AppTheme.textSecondary, fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ...KeyframeProperty.values.map((p) {
              final dummy = Keyframe(id: '', timeMs: 0, property: p, value: 0);
              return _KfPropertyChip(
                label: dummy.propertyLabel,
                icon: dummy.propertyIcon,
                onTap: () => editor.addKeyframe(
                  layerId: layer.id,
                  property: p,
                  value: dummy.defaultValue,
                ),
              );
            }),
          ]),
        ]),
      ),

      // Keyframe list
      Expanded(child: kfs.isEmpty
          ? const _EmptyKeyframes()
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: kfs.length,
        itemBuilder: (_, i) => _KeyframeItem(
          keyframe: kfs[i],
          layerColor: layer.color,
          isSelected: editor.selectedKeyframeId == kfs[i].id,
          onTap: () {
            editor.selectKeyframe(kfs[i].id);
            editor.seekTo(kfs[i].timeMs);
          },
          onDelete: () => editor.deleteKeyframe(layer.id, kfs[i].id),
          onValueChanged: (v) => editor.updateKeyframe(
              layer.id, kfs[i].copyWith(value: v)),
          onEasingChanged: (e) => editor.updateKeyframe(
              layer.id, kfs[i].copyWith(easing: e)),
        ),
      )),
    ]);
  }
}

class _EmptyKeyframes extends StatelessWidget {
  const _EmptyKeyframes();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.diamond_outlined, color: AppTheme.textHint, size: 32),
      const SizedBox(height: 8),
      const Text('No keyframes yet',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 4),
      const Text('Tap a property above to add one',
          style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
    ]),
  );
}

class _KfPropertyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _KfPropertyChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppTheme.accent, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _KeyframeItem extends StatelessWidget {
  final Keyframe keyframe;
  final Color layerColor;
  final bool isSelected;
  final VoidCallback onTap, onDelete;
  final Function(double) onValueChanged;
  final Function(EasingType) onEasingChanged;
  const _KeyframeItem({
    required this.keyframe, required this.layerColor, required this.isSelected,
    required this.onTap, required this.onDelete,
    required this.onValueChanged, required this.onEasingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final secs = keyframe.timeMs / 1000;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.bgHover : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? layerColor : AppTheme.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: layerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(keyframe.propertyIcon, color: layerColor, size: 14),
              const SizedBox(width: 4),
              Text(keyframe.propertyLabel, style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${secs.toStringAsFixed(2)}s',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    color: AppTheme.textHint, size: 14),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Slider(
                value: keyframe.value.clamp(keyframe.minValue, keyframe.maxValue),
                min: keyframe.minValue,
                max: keyframe.maxValue,
                onChanged: onValueChanged,
              )),
              SizedBox(
                width: 40,
                child: Text(keyframe.value.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),
            // Easing
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: EasingType.values.map((e) => _EasingChip(
                easing: e,
                selected: keyframe.easing == e,
                onTap: () => onEasingChanged(e),
              )).toList()),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EasingChip extends StatelessWidget {
  final EasingType easing;
  final bool selected;
  final VoidCallback onTap;
  const _EasingChip({required this.easing, required this.selected, required this.onTap});

  static const _names = {
    EasingType.linear: 'Lin',
    EasingType.easeIn: 'In',
    EasingType.easeOut: 'Out',
    EasingType.easeInOut: 'I/O',
    EasingType.bounce: 'Bnc',
    EasingType.elastic: 'Ela',
    EasingType.cubic: 'Cub',
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
      ),
      child: Text(_names[easing] ?? '',
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 9, fontWeight: FontWeight.w600)),
    ),
  );
}

// ── Shared UI ──────────────────────────────────────────────────────────────
class _PropSlider extends StatelessWidget {
  final String label, suffix;
  final double value, min, max;
  final Function(double) onChanged;
  const _PropSlider({
    required this.label, required this.value,
    required this.min, required this.max,
    required this.suffix, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${value.toStringAsFixed(1)}$suffix',
            style: const TextStyle(
                color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
      SizedBox(
        height: 30,
        child: Slider(value: value.clamp(min, max), min: min, max: max,
            onChanged: onChanged),
      ),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
    child: Text(label.toUpperCase(), style: const TextStyle(
        color: AppTheme.textHint, fontSize: 9,
        fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  );
}

class _ResetBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.refresh, size: 14),
    label: const Text('Reset All', style: TextStyle(fontSize: 12)),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTheme.textSecondary,
      side: const BorderSide(color: AppTheme.border),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
}
