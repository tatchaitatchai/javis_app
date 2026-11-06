import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ambient_widgets.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_sheet.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_switch.dart';
import '../../core/widgets/calm_text_field.dart';
import '../../core/widgets/failure_message.dart';
import '../../core/widgets/flow_page.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/step_bar.dart';
import '../lighting/light_labels.dart';
import '../lighting/lighting_service.dart';
import 'nearby_device_icon.dart';
import 'nearby_pairing.dart';
import 'pairing_widgets.dart';

enum _PairingStage { prepare, searching, found, failure, success, cancelled }

/// Opens “Add device” as a sheet-style page over the current tab.
void openAddDevice(BuildContext context, {String? zoneId}) {
  final lighting = context.app.lighting;
  Navigator.of(context).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => AddDeviceScreen(service: lighting, zoneId: zoneId),
    ),
  );
}

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({required this.service, this.zoneId, super.key});
  final LightingService service;

  /// Zone preselected on the naming step when setup starts from a zone.
  final String? zoneId;
  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  _PairingStage _stage = _PairingStage.prepare;
  bool _simulateFailure = false;
  LightDevice? _found;
  bool _alreadyAdded = false;
  LightingError? _error;
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  LightingError? _setupError;
  bool _preparingPairing = false;
  bool _hotspotReady = false;
  bool _discovering = false;
  bool _manualPairing = false;
  bool _editNetwork = false;
  DeviceHotspot? _discoveredHotspot;
  bool _loadingNetworks = false;
  List<String> _availableNetworks = const [];
  bool _wifiListUnavailable = false;
  int _setupGeneration = 0;
  bool _ezSelected = true;
  bool _checkingEz = false;
  PairingCapabilities? _capabilities;
  final _deviceName = TextEditingController();
  String? _zoneChoice;

  /// Every search starts on the radar (spec 018); Wi-Fi setup (EZ/AP) is the
  /// fallback for bulbs that never appear nearby.
  bool _nearbyMode = true;
  String? _selectedNearby;
  bool _scanStarting = false;

  bool get _usesNearby => _nearbyMode;

  bool get _onRadar =>
      _usesNearby &&
      _selectedNearby == null &&
      _stage == _PairingStage.prepare &&
      widget.service.readiness == LightingReadiness.ready;

  bool get _canPair {
    if (widget.service.isDemo) return true;
    return _usesNearby
        ? widget.service.readiness == LightingReadiness.ready &&
              !widget.service.preparingHome &&
              _selectedNearby != null &&
              _ssid.text.trim().isNotEmpty &&
              _password.text.isNotEmpty
        : widget.service.readiness == LightingReadiness.ready &&
              !widget.service.preparingHome &&
              !_preparingPairing &&
              !_discovering &&
              !_loadingNetworks &&
              (!_ezSelected ||
                  (!_checkingEz && (_capabilities?.ezAvailable ?? false))) &&
              _ssid.text.trim().isNotEmpty &&
              _password.text.isNotEmpty &&
              (_discoveredHotspot == null ||
                  _availableNetworks.contains(_ssid.text));
  }

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
    if (widget.service.readiness == LightingReadiness.ready) {
      // Starting a scan notifies other listeners, which cannot happen mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_startScan());
      });
    }
  }

  Future<void> _startScan() async {
    final generation = ++_setupGeneration;
    _scanStarting = true;
    setState(() {
      _setupError = null;
      _selectedNearby = null;
      _password.clear();
      _showPassword = false;
    });
    try {
      await widget.service.startDeviceScan();
    } on LightingException catch (error) {
      if (_isCurrentSetup(generation)) {
        setState(() => _setupError = error.code);
      }
    } finally {
      _scanStarting = false;
    }
  }

  void _onServiceChanged() {
    if (!mounted || !_usesNearby || _stage != _PairingStage.prepare) return;
    // A home that becomes ready later (restore, retry) starts its scan here.
    if (widget.service.readiness == LightingReadiness.ready &&
        !widget.service.scanning &&
        !widget.service.preparingHome &&
        !_scanStarting &&
        _selectedNearby == null &&
        _setupError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_scanStarting && !widget.service.scanning) {
          unawaited(_startScan());
        }
      });
    }
  }

  Future<void> _chooseNearby(String id) async {
    if (!widget.service.nearbyDevices.any((d) => d.id == id)) return;
    if (widget.service.isDemo) {
      setState(() => _selectedNearby = id);
      await _search();
      return;
    }
    final generation = _setupGeneration;
    setState(() {
      _selectedNearby = id;
      _setupError = null;
      _editNetwork = _ssid.text.isEmpty;
    });
    if (_ssid.text.isNotEmpty) return;
    String? ssid;
    try {
      ssid = await widget.service.currentWifi();
    } on LightingException {
      // Current network access is optional; manual entry remains usable.
    }
    if (!_isCurrentSetup(generation) || _selectedNearby != id) return;
    setState(() {
      if (ssid != null && _ssid.text.isEmpty) _ssid.text = ssid;
      _editNetwork = _ssid.text.isEmpty;
    });
  }

  Future<void> _useWifiSetup() async {
    _setupGeneration++;
    setState(() {
      _nearbyMode = false;
      _selectedNearby = null;
      _setupError = null;
      _password.clear();
      _showPassword = false;
    });
    await widget.service.stopDeviceScan();
    if (mounted && _ezSelected) await _loadEz();
  }

  Future<void> _useNearby() async {
    _setupGeneration++;
    setState(() {
      _nearbyMode = true;
      _preparingPairing = false;
      _discovering = false;
      _loadingNetworks = false;
      _manualPairing = false;
      _hotspotReady = false;
      _discoveredHotspot = null;
      _availableNetworks = const [];
      _wifiListUnavailable = false;
    });
    await widget.service.cancelSetup();
    if (mounted) await _startScan();
  }

  Future<void> _loadEz() async {
    final generation = ++_setupGeneration;
    setState(() {
      _checkingEz = true;
      _setupError = null;
      _capabilities = null;
    });
    try {
      final capabilities = await widget.service.pairingCapabilities();
      if (!_isCurrentSetup(generation)) return;
      setState(() => _capabilities = capabilities);
      if (!capabilities.ezAvailable) return;
      String? ssid;
      try {
        ssid = await widget.service.currentWifi();
      } on LightingException {
        // Current network access is optional; manual entry remains usable.
      }
      if (!_isCurrentSetup(generation)) return;
      setState(() {
        if (ssid != null) _ssid.text = ssid;
        _editNetwork = _ssid.text.isEmpty;
      });
    } on LightingException catch (error) {
      if (_isCurrentSetup(generation)) {
        setState(() => _setupError = error.code);
      }
    } finally {
      if (_isCurrentSetup(generation)) setState(() => _checkingEz = false);
    }
  }

  Future<void> _selectMode(bool ez) async {
    if (_ezSelected == ez) return;
    final generation = ++_setupGeneration;
    setState(() {
      _ezSelected = ez;
      _checkingEz = ez;
      _preparingPairing = false;
      _discovering = false;
      _loadingNetworks = false;
      _manualPairing = false;
      _hotspotReady = false;
      _discoveredHotspot = null;
      _availableNetworks = const [];
      _wifiListUnavailable = false;
      _setupError = null;
      _password.clear();
      _showPassword = false;
    });
    await widget.service.cancelSetup();
    if (_isCurrentSetup(generation) && ez) await _loadEz();
  }

  @override
  void dispose() {
    _setupGeneration++;
    widget.service.removeListener(_onServiceChanged);
    unawaited(widget.service.stopDeviceScan());
    unawaited(widget.service.cancelSetup());
    unawaited(widget.service.cancelPairing(notify: false));
    _password.clear();
    _password.dispose();
    _ssid.dispose();
    _deviceName.dispose();
    super.dispose();
  }

  Future<void> _prepareHome() async {
    if (widget.service.preparingHome) return;
    setState(() => _setupError = null);
    try {
      await widget.service.prepareHome();
      if (!mounted) return;
      if (_usesNearby) {
        await _startScan();
      } else if (_ezSelected) {
        await _loadEz();
      }
    } on LightingException catch (error) {
      if (mounted) setState(() => _setupError = error.code);
    }
  }

  Future<void> _preparePairing() async {
    if (!_canPair) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _preparingPairing = true;
      _setupError = null;
    });
    final generation = ++_setupGeneration;
    try {
      await widget.service.preparePairing();
      if (_isCurrentSetup(generation)) {
        setState(() {
          _hotspotReady = true;
          _preparingPairing = false;
        });
        if (_ezSelected) await _search();
      }
    } on LightingException catch (error) {
      if (_isCurrentSetup(generation)) {
        setState(() => _setupError = error.code);
      }
    } finally {
      if (_isCurrentSetup(generation)) {
        setState(() => _preparingPairing = false);
      }
    }
  }

  bool _isCurrentSetup(int generation) =>
      mounted && generation == _setupGeneration;

  Future<void> _discover() async {
    if (_discovering ||
        _preparingPairing ||
        widget.service.readiness != LightingReadiness.ready) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (_setupError != null) await widget.service.cancelSetup();
    if (!mounted) return;
    final generation = ++_setupGeneration;
    setState(() {
      _discovering = true;
      _setupError = null;
      _discoveredHotspot = null;
      _hotspotReady = false;
      _wifiListUnavailable = false;
    });
    try {
      // Read the home network before the system joins the setup hotspot.
      // Permission is optional: manual network entry remains available.
      String? currentNetwork;
      try {
        currentNetwork = await widget.service.currentWifi();
      } on LightingException {
        currentNetwork = null;
      }
      if (!_isCurrentSetup(generation)) return;
      if (_ssid.text.isEmpty && currentNetwork != null) {
        _ssid.text = currentNetwork;
      }
      await widget.service.preparePairing();
      if (!_isCurrentSetup(generation)) return;
      final hotspot = await widget.service.discoverBulbHotspot();
      if (!_isCurrentSetup(generation)) return;
      setState(() {
        _discoveredHotspot = hotspot;
        _manualPairing = false;
        _hotspotReady = true;
        _editNetwork = _ssid.text.isEmpty;
        _discovering = false;
        _loadingNetworks = true;
      });
      // Only show choices actually returned by the device. Older firmware may
      // not support this query; the captured home network remains usable.
      var networks = <String>[];
      try {
        networks = await widget.service.listBulbWifi();
      } on LightingException {
        networks = [];
      }
      if (!_isCurrentSetup(generation)) return;
      if (networks.isEmpty) {
        _useManualPairing(wifiListUnavailable: true);
        return;
      }
      setState(() {
        _availableNetworks = networks;
        _loadingNetworks = false;
        if (!networks.contains(_ssid.text)) {
          _ssid.clear();
          _password.clear();
        }
        _editNetwork = false;
      });
    } on LightingException catch (error) {
      if (_isCurrentSetup(generation)) {
        setState(() => _setupError = error.code);
      }
    } finally {
      if (_isCurrentSetup(generation)) {
        setState(() => _discovering = false);
      }
    }
  }

  void _useManualPairing({bool wifiListUnavailable = false}) => setState(() {
    _setupGeneration++;
    unawaited(widget.service.cancelSetup());
    _discovering = false;
    _manualPairing = true;
    _hotspotReady = false;
    _discoveredHotspot = null;
    _availableNetworks = const [];
    _loadingNetworks = false;
    _wifiListUnavailable = wifiListUnavailable;
    _setupError = null;
    _password.clear();
    _showPassword = false;
    _editNetwork = _ssid.text.isEmpty;
  });

  Future<void> _search() async {
    if (_stage == _PairingStage.searching ||
        !_canPair ||
        (!widget.service.isDemo && !_usesNearby && !_hotspotReady)) {
      return;
    }
    final network = widget.service.isDemo
        ? null
        : WifiPairingConfiguration(
            ssid: _ssid.text,
            password: _password.text,
            mode: _usesNearby
                ? WifiPairingMode.ble
                : _ezSelected
                ? WifiPairingMode.ez
                : WifiPairingMode.ap,
            deviceId: _usesNearby ? _selectedNearby : null,
          );
    FocusScope.of(context).unfocus();
    setState(() {
      _stage = _PairingStage.searching;
      _error = null;
      _password.clear();
      _showPassword = false;
      _hotspotReady = false;
    });
    try {
      final light = await widget.service.startPairing(
        simulateFailure: _simulateFailure,
        network: network,
      );
      if (!mounted) return;
      setState(() {
        _found = light;
        _stage = widget.service.isDemo
            ? _PairingStage.found
            : _PairingStage.success;
      });
      _prefillLabel(light);
    } on LightingException catch (error) {
      if (mounted) {
        setState(() {
          _simulateFailure = false;
          _error = error.code;
          _stage = error.code == LightingError.cancelled
              ? _PairingStage.cancelled
              : _PairingStage.failure;
        });
      }
    }
  }

  void _add() {
    if (_stage != _PairingStage.found || _found == null) return;
    _alreadyAdded = widget.service.devices.any((d) => d.id == _found!.id);
    widget.service.confirmPairing(_found!);
    _prefillLabel(_found!);
    setState(() => _stage = _PairingStage.success);
  }

  void _prefillLabel(LightDevice light) {
    if (_deviceName.text.isEmpty) _deviceName.text = context.lightName(light);
    _zoneChoice ??= widget.zoneId ?? context.app.homes.zoneIdFor(light);
  }

  /// Saves the name and zone chosen after pairing.
  void _saveLabel() {
    final found = _found;
    if (found == null) return;
    final typed = _deviceName.text.trim();
    final name = typed == context.lightName(found) ? null : typed;
    final homes = context.app.homes;
    final zoneId = _zoneChoice;
    unawaited(
      attempt(
        context,
        () => homes.labelDevice(
          widget.service,
          found.id,
          name: name,
          zoneId: zoneId,
        ),
      ),
    );
  }

  void _finish() {
    _saveLabel();
    Navigator.of(context).pop();
  }

  void _addNext() {
    _saveLabel();
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(
        builder: (_) =>
            AddDeviceScreen(service: widget.service, zoneId: widget.zoneId),
      ),
    );
  }

  int get _step {
    if (widget.service.isDemo) {
      return switch (_stage) {
        _PairingStage.prepare => 1,
        _PairingStage.searching ||
        _PairingStage.failure ||
        _PairingStage.cancelled => 2,
        _PairingStage.found || _PairingStage.success => 3,
      };
    }
    if (_stage != _PairingStage.prepare) return 3;
    if (_usesNearby) return _selectedNearby == null ? 1 : 2;
    if (_ezSelected) return 2;
    if (_discoveredHotspot != null) return 2;
    if (_manualPairing) return _hotspotReady ? 3 : 2;
    return 1;
  }

  void _retry() {
    setState(() {
      _setupGeneration++;
      unawaited(widget.service.cancelSetup());
      _stage = _PairingStage.prepare;
      _setupError = null;
      _hotspotReady = false;
      _discoveredHotspot = null;
      _availableNetworks = const [];
      _loadingNetworks = false;
      _wifiListUnavailable = false;
      _manualPairing = false;
    });
    if (_usesNearby) {
      unawaited(_startScan());
    } else if (_ezSelected) {
      unawaited(_loadEz());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.service,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Pinned so Back stays reachable on long forms.
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: FlowTopBar(
                    leading: const CalmBackButton(close: true),
                    center: Semantics(
                      label: context.l10n.pairingStep(_step),
                      excludeSemantics: true,
                      child: StepBar(current: _step),
                    ),
                  ),
                ),
                Expanded(child: _body(context)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : _actionBar(context),
    ),
  );

  Widget _body(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
    children: [
      _hero(context),
      const SizedBox(height: 24),
      if (!widget.service.isDemo &&
          !_nearbyMode &&
          widget.service.readiness == LightingReadiness.ready &&
          _stage == _PairingStage.prepare) ...[
        _modeSelector(context),
        const SizedBox(height: 18),
      ],
      ..._content(context),
      if (widget.service.isDemo)
        DemoNote(text: context.l10n.pairingNote)
      else if (!_onRadar)
        DemoNote(text: context.l10n.realDeviceMode),
    ],
  );

  Widget _hero(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (_stage) {
      _PairingStage.prepare =>
        widget.service.readiness != LightingReadiness.ready
            ? widget.service.readiness == LightingReadiness.sessionRequired
                  ? l10n.pairingHomeTitle
                  : l10n.providerStatus(widget.service.readiness.name)
            : _usesNearby
            ? _selectedNearby == null
                  ? l10n.nearbyTitle
                  : l10n.pairingNetworkTitle
            : _discoveredHotspot != null
            ? l10n.pairingNetworkTitle
            : _ezSelected
            ? l10n.ezPairingTitle
            : !_manualPairing
            ? l10n.discoverHotspotTitle
            : _hotspotReady
            ? l10n.pairingHotspotTitle
            : l10n.pairingNetworkTitle,
      _PairingStage.searching => l10n.pairingSearching,
      _PairingStage.found => l10n.pairingFound,
      _PairingStage.failure => l10n.pairingFailure,
      _PairingStage.cancelled => l10n.pairingCancelled,
      _PairingStage.success =>
        _alreadyAdded ? l10n.pairingAlready : l10n.pairingSuccess,
    };
    final description = switch (_stage) {
      _PairingStage.prepare =>
        widget.service.readiness != LightingReadiness.ready
            ? widget.service.readiness == LightingReadiness.sessionRequired
                  ? l10n.pairingHomeIntro
                  : l10n.providerDescription(widget.service.readiness.name)
            : _usesNearby
            ? _selectedNearby == null
                  ? l10n.nearbyIntro
                  : l10n.nearbySelected
            : _discoveredHotspot != null
            ? l10n.discoveredNetworkIntro
            : _ezSelected
            ? l10n.ezPairingIntro
            : !_manualPairing
            ? l10n.discoverHotspotIntro
            : _hotspotReady
            ? l10n.pairingHotspotIntro
            : l10n.pairingNetworkIntro,
      _PairingStage.searching =>
        widget.service.isDemo
            ? l10n.searchingDescription
            : widget.service.pairing?.phase == PairingPhase.activating
            ? l10n.activatingLight
            : l10n.connectingLight,
      _PairingStage.found => l10n.foundDescription,
      _PairingStage.failure =>
        widget.service.isDemo
            ? l10n.failureDescription
            : _usesNearby &&
                  (_error == LightingError.timeout ||
                      _error == LightingError.pairingFailed)
            ? l10n.nearbyRetryTip
            : _ezSelected &&
                  (_error == LightingError.timeout ||
                      _error == LightingError.pairingFailed)
            ? l10n.ezRetryTip
            : l10n.lightingError(
                (_error ?? LightingError.transportFailure).name,
              ),
      _PairingStage.cancelled => l10n.cancelledDescription,
      _PairingStage.success =>
        _alreadyAdded
            ? l10n.alreadyDescription
            : widget.service.isDemo
            ? l10n.successDescription
            : l10n.connectedDescription,
    };
    final centered = _stage != _PairingStage.prepare;
    final heading = Semantics(
      liveRegion: true,
      child: Text(
        title,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
    final body = Text(
      description,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: 15.5,
        height: 1.6,
        color: context.palette.textMuted,
      ),
    );
    if (!centered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [heading, const SizedBox(height: 8), body],
      );
    }
    final success = _stage == _PairingStage.success;
    return Column(
      children: [
        PairingOrb(
          icon: success
              ? CupertinoIcons.checkmark_alt
              : _stage == _PairingStage.failure ||
                    _stage == _PairingStage.cancelled
              ? CupertinoIcons.arrow_clockwise
              : CupertinoIcons.lightbulb_fill,
          busy: _stage == _PairingStage.searching,
          done: success,
        ),
        const SizedBox(height: 18),
        heading,
        const SizedBox(height: 6),
        body,
      ],
    );
  }

  List<Widget> _content(BuildContext context) {
    final l10n = context.l10n;
    if (_stage == _PairingStage.searching) {
      if (widget.service.isDemo) {
        return [_note(CupertinoIcons.clock, l10n.searchingDevices)];
      }
      final activating =
          widget.service.pairing?.phase == PairingPhase.activating;
      return [
        PairingChecklist(
          steps: [
            (
              l10n.stepSendWifi,
              activating ? ChecklistState.done : ChecklistState.active,
            ),
            (
              l10n.stepWaitOnline,
              activating ? ChecklistState.active : ChecklistState.waiting,
            ),
            (
              l10n.stepAddToHome(context.app.homes.activeHome?.name ?? ''),
              ChecklistState.waiting,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _note(CupertinoIcons.clock, l10n.pairingWaitingHint),
      ];
    }
    if (_stage == _PairingStage.cancelled) return [];
    if (_stage == _PairingStage.failure) {
      return [
        _note(
          CupertinoIcons.arrow_clockwise,
          widget.service.isDemo
              ? l10n.failureDescription
              : _usesNearby
              ? l10n.nearbyRetryTip
              : _ezSelected
              ? l10n.ezRetryTip
              : l10n.pairingRetryTip,
        ),
      ];
    }
    if (_stage == _PairingStage.found) {
      return [
        if (_found != null)
          _note(CupertinoIcons.lightbulb_fill, context.lightName(_found!)),
      ];
    }
    if (_stage == _PairingStage.success) {
      return [if (_found != null) _successForm(context)];
    }
    if (widget.service.readiness != LightingReadiness.ready) {
      return [
        _note(
          widget.service.readiness == LightingReadiness.sessionRequired
              ? CupertinoIcons.house_fill
              : CupertinoIcons.exclamationmark_circle,
          widget.service.readiness == LightingReadiness.sessionRequired
              ? l10n.demoHomeDescription
              : l10n.providerDescription(widget.service.readiness.name),
        ),
        if (_setupError != null) _errorText(context, _setupError!),
      ];
    }
    if (_usesNearby) {
      if (_selectedNearby == null) {
        return [
          NearbyScanView(
            bluetooth: widget.service.bluetooth,
            devices: widget.service.nearbyDevices,
            onChoose: _chooseNearby,
          ),
          if (_setupError != null) _errorText(context, _setupError!),
          if (widget.service.isDemo) ...[
            const SizedBox(height: 8),
            ListRow(
              title: l10n.previewFailure,
              subtitle: l10n.optionalDemo,
              onTap: () => setState(() => _simulateFailure = !_simulateFailure),
              trailing: CalmSwitch(
                value: _simulateFailure,
                semanticLabel: l10n.previewFailure,
                onChanged: (value) => setState(() => _simulateFailure = value),
              ),
            ),
          ],
        ];
      }
      return [
        _note(
          CupertinoIcons.dot_radiowaves_left_right,
          _selectedNearbyLabel(context),
        ),
        const SizedBox(height: 20),
        _networkForm(context),
        if (_setupError != null) _errorText(context, _setupError!),
      ];
    }
    if (_ezSelected) {
      if (_checkingEz) {
        return [_note(CupertinoIcons.clock, l10n.checkingPairingSupport)];
      }
      if (!(_capabilities?.ezAvailable ?? false)) {
        return [
          _note(
            CupertinoIcons.exclamationmark_circle,
            _capabilities?.ezReason == 'multicastEntitlementRequired'
                ? l10n.ezEntitlementRequired
                : l10n.ezSupportUnavailable,
          ),
          if (_setupError != null) _errorText(context, _setupError!),
        ];
      }
      return [
        _note(CupertinoIcons.lightbulb, l10n.ezBulbHint),
        const SizedBox(height: 20),
        _networkForm(context),
        if (_setupError != null) _errorText(context, _setupError!),
      ];
    }
    if (_discovering) {
      return [
        CalmPanel(
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(l10n.discoveringHotspotHint),
                ),
              ),
            ],
          ),
        ),
      ];
    }
    if (_discoveredHotspot != null) {
      return [
        _note(CupertinoIcons.wifi, l10n.deviceHotspotFound),
        const SizedBox(height: 20),
        _networkForm(context),
        if (_setupError != null) _errorText(context, _setupError!),
      ];
    }
    if (!_manualPairing) {
      return [
        if (_setupError != null) ...[
          _errorText(context, _setupError!),
          const SizedBox(height: 14),
        ],
        _note(CupertinoIcons.lightbulb, l10n.pairingBulbTipBody),
        const SizedBox(height: 12),
        _note(CupertinoIcons.location, l10n.wifiPermissionHint),
      ];
    }
    if (_hotspotReady) return [_hotspotInstructions(context)];
    return [
      if (_wifiListUnavailable) ...[
        _note(CupertinoIcons.wifi, l10n.wifiListUnavailable),
        const SizedBox(height: 14),
      ],
      _networkForm(context),
      const SizedBox(height: 14),
      InfoNote(
        icon: CupertinoIcons.lightbulb,
        title: l10n.pairingBulbTipTitle,
        text: l10n.pairingBulbTipBody,
      ),
      if (_setupError != null) _errorText(context, _setupError!),
    ];
  }

  Widget _note(IconData icon, String text) => InfoNote(icon: icon, text: text);

  /// Matches the label the scan list showed for this device.
  String _selectedNearbyLabel(BuildContext context) {
    final devices = widget.service.nearbyDevices;
    final index = devices.indexWhere((d) => d.id == _selectedNearby);
    return index < 0
        ? context.l10n.nearbyDeviceNumbered(1)
        : context.nearbyDeviceName(devices[index], index);
  }

  Widget _modeSelector(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.l10n.connectionMethodTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      for (final ez in [true, false])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ModeOption(
            key: ValueKey(ez ? 'pairing-mode-ez' : 'pairing-mode-ap'),
            label: ez
                ? context.l10n.homeWifiEzMode
                : context.l10n.bulbWifiApMode,
            selected: _ezSelected == ez,
            onTap: _preparingPairing ? null : () => _selectMode(ez),
          ),
        ),
    ],
  );

  Widget _errorText(BuildContext context, LightingError error) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        context.l10n.lightingError(error.name),
        style: TextStyle(color: context.palette.danger),
      ),
    ),
  );

  Widget _hotspotInstructions(BuildContext context) {
    final l10n = context.l10n;
    return CalmPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberedSteps(
            steps: [
              l10n.pairingOpenSettings,
              l10n.pairingJoinHotspot,
              l10n.pairingReturnToApp,
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: context.palette.hairline),
          const SizedBox(height: 12),
          Text(
            l10n.pairingHotspotHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _actionBar(BuildContext context) {
    final l10n = context.l10n;
    final String label;
    final VoidCallback? action;
    var loading = false;
    var showPrimary = true;
    switch (_stage) {
      case _PairingStage.prepare:
        if (widget.service.readiness == LightingReadiness.sessionRequired) {
          label = widget.service.preparingHome
              ? l10n.preparingHome
              : l10n.prepareDemoHome;
          loading = widget.service.preparingHome;
          action = widget.service.preparingHome ? null : _prepareHome;
        } else if (widget.service.readiness != LightingReadiness.ready) {
          label = l10n.retry;
          action = widget.service.readiness == LightingReadiness.initializing
              ? null
              : widget.service.initialize;
        } else if (_usesNearby) {
          if (_selectedNearby != null) {
            label = l10n.connectDevice;
            action = _canPair ? _search : null;
          } else if (_setupError != null) {
            label = l10n.retry;
            action = _startScan;
          } else {
            // The radar shows the search, and each found device has its Add.
            showPrimary = false;
            label = '';
            action = null;
          }
        } else if (_ezSelected) {
          label = _checkingEz
              ? l10n.checkingPairingSupport
              : _preparingPairing
              ? l10n.preparingConnection
              : (_capabilities?.ezAvailable ?? false)
              ? l10n.realPairing
              : l10n.retry;
          loading = _checkingEz || _preparingPairing;
          action = _checkingEz || _preparingPairing
              ? null
              : (_capabilities?.ezAvailable ?? false)
              ? (_canPair ? _preparePairing : null)
              : _loadEz;
        } else if (_discovering) {
          label = l10n.discoveringHotspot;
          loading = true;
          action = null;
        } else if (_discoveredHotspot != null) {
          label = l10n.realPairing;
          action = _canPair ? _search : null;
        } else if (!_manualPairing) {
          label = _setupError == null ? l10n.discoverHotspot : l10n.retry;
          action = _discover;
        } else if (_hotspotReady) {
          label = l10n.pairingPreparedAction;
          action = _canPair ? _search : null;
        } else {
          label = _preparingPairing
              ? l10n.preparingConnection
              : l10n.prepareConnection;
          loading = _preparingPairing;
          action = _canPair ? _preparePairing : null;
        }
      case _PairingStage.searching:
        label = l10n.cancel;
        action = widget.service.cancelPairing;
      case _PairingStage.found:
        label = l10n.addToHome;
        action = _add;
      case _PairingStage.failure || _PairingStage.cancelled:
        label = l10n.retry;
        action = widget.service.isDemo ? _search : _retry;
      case _PairingStage.success:
        label = l10n.done;
        action = _finish;
    }
    final primary = _stage == _PairingStage.searching
        ? SecondaryButton(label: label, onPressed: action)
        : PrimaryButton(label: label, onPressed: action, loading: loading);
    return ColoredBox(
      color: context.palette.canvas,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showPrimary) primary,
                  ..._modeButtons(context),
                  if (_stage == _PairingStage.prepare &&
                      !widget.service.isDemo &&
                      !_nearbyMode &&
                      widget.service.readiness == LightingReadiness.ready &&
                      !_discovering &&
                      !_preparingPairing &&
                      !_manualPairing &&
                      !_ezSelected &&
                      _discoveredHotspot == null)
                    QuietButton(
                      label: l10n.pairManually,
                      onPressed: _useManualPairing,
                    ),
                  if (_stage == _PairingStage.prepare &&
                      !_nearbyMode &&
                      _hotspotReady &&
                      !_ezSelected &&
                      _discoveredHotspot == null)
                    QuietButton(
                      label: l10n.editWifi,
                      onPressed: () => setState(() => _hotspotReady = false),
                    ),
                  if (_stage == _PairingStage.success)
                    QuietButton(label: l10n.addNextLight, onPressed: _addNext),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Switches between the Bluetooth scan and the Wi-Fi (EZ/AP) fallback.
  List<Widget> _modeButtons(BuildContext context) {
    final l10n = context.l10n;
    if (_stage != _PairingStage.prepare ||
        widget.service.isDemo ||
        widget.service.readiness != LightingReadiness.ready) {
      return const [];
    }
    if (_nearbyMode) {
      return [
        if (_selectedNearby != null)
          QuietButton(
            label: l10n.chooseAnotherDevice,
            onPressed: () => setState(() {
              _selectedNearby = null;
              _setupError = null;
              _password.clear();
              _showPassword = false;
            }),
          )
        else
          QuietButton(
            key: const ValueKey('use-wifi-setup'),
            label: l10n.useWifiSetup,
            onPressed: _useWifiSetup,
          ),
      ];
    }
    if (_discovering || _preparingPairing || _loadingNetworks) return const [];
    return [
      QuietButton(
        key: const ValueKey('use-nearby-setup'),
        label: l10n.useNearbySetup,
        onPressed: _useNearby,
      ),
    ];
  }

  Widget _wifiBox(BuildContext context, {required Widget child}) {
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.line, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.wifi, size: 20, color: palette.accentDeep),
          const SizedBox(width: 12),
          Expanded(child: child),
          StatusBadge(context.l10n.band24, subtle: true),
        ],
      ),
    );
  }

  Widget _networkForm(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.wifiDetails, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          _discoveredHotspot != null
              ? l10n.discoveredWifiDescription
              : l10n.wifiDetailsDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (_loadingNetworks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(l10n.findingWifiNetworks),
            ),
          ),
        if (_availableNetworks.isNotEmpty)
          Pressable(
            key: const ValueKey('choose-home-wifi'),
            onPressed: _loadingNetworks ? null : _chooseWifi,
            pressedScale: .98,
            child: _wifiBox(
              context,
              child: Text(
                _ssid.text.isEmpty ? l10n.chooseWifi : _ssid.text,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          )
        else if (!_editNetwork && _ssid.text.isNotEmpty)
          _wifiBox(
            context,
            child: Text(
              _ssid.text,
              key: const ValueKey('selected-home-wifi'),
              style: const TextStyle(fontSize: 17),
            ),
          ),
        if (!_editNetwork && _ssid.text.isNotEmpty ||
            _availableNetworks.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: QuietButton(
              label: l10n.useAnotherNetwork,
              onPressed: _loadingNetworks
                  ? null
                  : _availableNetworks.isNotEmpty
                  ? () => _useManualPairing(wifiListUnavailable: true)
                  : () => setState(() {
                      _editNetwork = true;
                      _password.clear();
                    }),
            ),
          ),
        if (_editNetwork || (_availableNetworks.isEmpty && _ssid.text.isEmpty))
          CalmTextField(
            label: l10n.wifiName,
            fieldKey: const ValueKey('pairing-ssid'),
            controller: _ssid,
            private: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
        const SizedBox(height: 16),
        CalmTextField(
          label: l10n.wifiPassword,
          fieldKey: const ValueKey('pairing-password'),
          controller: _password,
          private: true,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_canPair) {
              unawaited(
                _usesNearby || _discoveredHotspot != null
                    ? _search()
                    : _preparePairing(),
              );
            }
          },
          suffix: IconButton(
            tooltip: _showPassword ? l10n.hidePassword : l10n.showPassword,
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              color: context.palette.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 14),
        InfoNote(
          icon: CupertinoIcons.exclamationmark_triangle,
          tone: NoteTone.warm,
          text: l10n.wifi24Only,
        ),
        const SizedBox(height: 10),
        Text(l10n.wifiPrivacy, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  /// Design 18: name the new light and choose its zone.
  Widget _successForm(BuildContext context) {
    final l10n = context.l10n;
    final zones = context.app.homes.activeHome?.zones ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalmTextField(
          label: l10n.deviceName,
          controller: _deviceName,
          textInputAction: TextInputAction.done,
        ),
        if (zones.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            l10n.whichZone,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final zone in zones)
                SelectPill(
                  label: zone.label(l10n),
                  selected: _zoneChoice == zone.id,
                  onTap: () => setState(() => _zoneChoice = zone.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.nameStaysLocal, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Future<void> _chooseWifi() async {
    FocusScope.of(context).unfocus();
    final generation = _setupGeneration;
    final selected = await showCalmSheet<String>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sheetContext.l10n.chooseWifi,
            style: Theme.of(sheetContext).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          for (final ssid in _availableNetworks)
            ListRow(
              leading: const Icon(CupertinoIcons.wifi),
              title: ssid,
              trailing: ssid == _ssid.text
                  ? Icon(
                      CupertinoIcons.checkmark_alt,
                      color: sheetContext.palette.accent,
                    )
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(ssid),
            ),
        ],
      ),
    );
    if (!_isCurrentSetup(generation) || selected == null) return;
    setState(() {
      if (_ssid.text != selected) _password.clear();
      _ssid.text = selected;
      _editNetwork = false;
    });
  }
}
