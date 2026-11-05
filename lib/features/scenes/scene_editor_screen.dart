import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_segment.dart';
import '../../core/widgets/calm_sheet.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_text_field.dart';
import '../../core/widgets/failure_message.dart';
import '../../core/widgets/flow_page.dart';
import '../lighting/light_labels.dart';
import 'scene_labels.dart';
import 'scene_models.dart';

/// 20 · Edit a scene, or build a new one when [sceneId] is null. Changes
/// stay in a local draft until Save.
class SceneEditorScreen extends StatefulWidget {
  const SceneEditorScreen({this.sceneId, super.key});
  final String? sceneId;

  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  late Scene _original;
  late List<SceneAction> _actions;
  late final TextEditingController _name;
  bool _isNew = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final scenes = context.app.scenes;
    final existing = widget.sceneId == null
        ? null
        : scenes.byId(widget.sceneId!);
    _isNew = existing == null;
    _original = existing ?? scenes.draft();
    _actions = [..._original.actions];
    _name = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_name.text.isEmpty && !_isNew) {
      _name.text = _original.label(context.l10n);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && _actions.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    final typed = _name.text.trim();
    final keepPreset =
        _original.presetKey != null && typed == _original.label(context.l10n);
    final scenes = context.app.scenes;
    setState(() => _saving = true);
    final saved = await attempt(
      context,
      () => scenes.save(
        _original.copyWith(
          actions: _actions,
          customName: keepPreset ? null : typed,
          clearPreset: !keepPreset,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) return;
    Haptics.confirm();
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.deleteSceneQuestion(_original.label(l10n))),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final scenes = context.app.scenes;
    final deleted = await attempt(context, () => scenes.delete(_original.id));
    if (!deleted || !mounted) return;
    Haptics.warn();
    Navigator.of(context).pop();
  }

  Future<void> _addAction() async {
    final action = await showCalmSheet<SceneAction>(
      context: context,
      builder: (_) => _TargetPicker(existing: _actions),
    );
    if (action == null || !mounted) return;
    setState(() => _actions = [..._actions, action]);
    if (action is LightAction) await _editAction(_actions.length - 1);
  }

  Future<void> _editAction(int index) async {
    final action = _actions[index];
    if (action is! LightAction) return;
    final title = context.actionTitle(action);
    final edited = await showCalmSheet<LightAction>(
      context: context,
      builder: (_) => _LightActionForm(title: title, initial: action),
    );
    if (edited == null || !mounted) return;
    setState(
      () => _actions = [
        for (final (i, item) in _actions.indexed) i == index ? edited : item,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return FlowPage(
      top: FlowTopBar(
        leading: QuietButton(
          label: l10n.cancel,
          accent: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        center: Text(
          _isNew ? l10n.newScene : l10n.editScene,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: QuietButton(
          label: l10n.save,
          onPressed: _canSave && !_saving ? _save : null,
        ),
      ),
      footer: _isNew
          ? null
          : SecondaryButton(
              label: l10n.deleteScene,
              destructive: true,
              onPressed: _delete,
            ),
      children: [
        const SizedBox(height: 12),
        CalmTextField(
          label: l10n.sceneName,
          controller: _name,
          hint: l10n.sceneNameHint,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
        ),
        SectionHeader(l10n.whenSceneStarts),
        if (_actions.isEmpty)
          InfoNote(text: l10n.noActionsYet, icon: CupertinoIcons.sparkles)
        else
          ListGroup(
            children: [
              for (final (index, action) in _actions.indexed)
                ListRow(
                  key: ObjectKey(action),
                  leading: Icon(
                    action is LockCheckAction
                        ? CupertinoIcons.lock_fill
                        : CupertinoIcons.lightbulb_fill,
                    color: palette.accentDeep,
                    size: 22,
                  ),
                  title: context.actionTitle(action),
                  subtitle: context.actionDetail(action),
                  onTap: action is LightAction
                      ? () => _editAction(index)
                      : null,
                  trailing: IconButton(
                    tooltip: l10n.removeAction(context.actionTitle(action)),
                    onPressed: () => setState(
                      () => _actions = [..._actions]..removeAt(index),
                    ),
                    icon: Icon(
                      CupertinoIcons.minus_circle,
                      color: palette.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),
        DashedButton(label: l10n.addAction, onPressed: _addAction),
        SectionHeader(l10n.startSceneFrom),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SelectPill(label: l10n.tapInApp, selected: true, onTap: null),
            SelectPill(
              label: l10n.sayPhrase(
                _name.text.trim().isEmpty ? l10n.newScene : _name.text.trim(),
              ),
              selected: false,
              onTap: null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.voicePreviewOnly,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Chooses what a new action applies to.
class _TargetPicker extends StatelessWidget {
  const _TargetPicker({required this.existing});
  final List<SceneAction> existing;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l10n = context.l10n;
    final zones = (app.homes.activeHome?.zones ?? const [])
        .where((zone) => zone.presetKey != null)
        .toList();
    final hasLockCheck = existing.any((action) => action is LockCheckAction);
    void pick(SceneAction action) => Navigator.of(context).pop(action);
    const defaults = (isOn: true, brightness: .8, temperature: 3000);
    LightAction light(LightTarget target) => LightAction(
      target: target,
      isOn: defaults.isOn,
      brightness: defaults.brightness,
      temperature: defaults.temperature,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.addAction, style: Theme.of(context).textTheme.headlineSmall),
        SectionHeader(
          l10n.lightsSection,
          padding: const EdgeInsets.only(top: 16, bottom: 8),
        ),
        ListGroup(
          children: [
            ListRow(
              title: l10n.allLights,
              chevron: true,
              onTap: () => pick(light(const LightTarget.all())),
            ),
            ListRow(
              title: l10n.otherLights,
              subtitle: l10n.otherLightsHint,
              chevron: true,
              onTap: () => pick(light(const LightTarget.others())),
            ),
            for (final zone in zones)
              ListRow(
                title: zone.label(l10n),
                chevron: true,
                onTap: () => pick(light(LightTarget.zone(zone.presetKey!))),
              ),
            for (final device in app.homes.lightsIn(app.lighting))
              ListRow(
                title: context.lightName(device),
                subtitle: context.lightZone(device),
                chevron: true,
                onTap: () => pick(light(LightTarget.device(device.id))),
              ),
          ],
        ),
        if (!hasLockCheck) ...[
          SectionHeader(
            l10n.door,
            padding: const EdgeInsets.only(top: 16, bottom: 8),
          ),
          ListGroup(
            children: [
              ListRow(
                title: l10n.frontDoor,
                subtitle: l10n.lockCheckDetail,
                chevron: true,
                onTap: () => pick(const LockCheckAction()),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// On/off, brightness and tone for one light action.
class _LightActionForm extends StatefulWidget {
  const _LightActionForm({required this.title, required this.initial});
  final String title;
  final LightAction initial;

  @override
  State<_LightActionForm> createState() => _LightActionFormState();
}

class _LightActionFormState extends State<_LightActionForm> {
  static const _levels = [.1, .3, .5, .8, 1.0];
  static const _tones = [2700, 4000, 6000];

  late bool _on = widget.initial.isOn;
  late double _brightness = _nearest(_levels, widget.initial.brightness ?? .8);
  late int _tone = _nearest(_tones, widget.initial.temperature ?? 3000);

  static T _nearest<T extends num>(List<T> options, num value) =>
      options.reduce((a, b) => (a - value).abs() <= (b - value).abs() ? a : b);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        CalmSegment<bool>(
          options: [(true, l10n.on), (false, l10n.off)],
          selected: _on,
          onChanged: (value) => setState(() => _on = value),
        ),
        AnimatedSize(
          duration: Motion.of(context, Motion.standard),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: !_on
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      l10n.brightness,
                      padding: const EdgeInsets.only(top: 18, bottom: 8),
                    ),
                    CalmSegment<double>(
                      options: [
                        for (final level in _levels)
                          (level, '${(level * 100).round()}%'),
                      ],
                      selected: _brightness,
                      onChanged: (value) => setState(() => _brightness = value),
                    ),
                    SectionHeader(
                      l10n.temperature,
                      padding: const EdgeInsets.only(top: 18, bottom: 8),
                    ),
                    CalmSegment<int>(
                      options: [
                        for (final tone in _tones)
                          (tone, l10n.temperatureFeel(tone)),
                      ],
                      selected: _tone,
                      onChanged: (value) => setState(() => _tone = value),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: l10n.done,
          onPressed: () => Navigator.of(context).pop(
            LightAction(
              target: widget.initial.target,
              isOn: _on,
              brightness: _on ? _brightness : null,
              temperature: _on ? _tone : null,
            ),
          ),
        ),
      ],
    );
  }
}
