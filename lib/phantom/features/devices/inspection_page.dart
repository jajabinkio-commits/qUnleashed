import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/localization/l10n.dart';
import '../../../services/guarded.dart';
import '../../core/device_snapshot.dart';
import '../../device/device_gateway.dart';

/// Manual, local-only inspection using the same client as the retained UI.
class PhantomInspectionPage extends StatefulWidget {
  const PhantomInspectionPage({super.key, required this.createGateway});

  /// This route owns the adapter, but the adapter never owns the BLE client.
  final DeviceGateway Function() createGateway;

  @override
  State<PhantomInspectionPage> createState() => _PhantomInspectionPageState();
}

class _PhantomInspectionPageState extends State<PhantomInspectionPage>
    with WidgetsBindingObserver {
  late final DeviceGateway _gateway;
  StreamSubscription<DeviceSnapshot>? _watch;
  DeviceSnapshot? _snapshot;
  CapabilityReport? _capabilities;
  bool _busy = false;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _gateway = widget.createGateway();
    WidgetsBinding.instance.addObserver(this);
    _watch = _gateway.watchDevice().listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _snapshot = snapshot;
          _capabilities = null;
        });
      },
      onError: (Object _) {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  Future<void> _inspect() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final snapshot = await _gateway.readStatus();
      final capabilities = await _gateway.discoverCapabilities();
      if (!mounted || generation != _generation) return;
      setState(() {
        _snapshot = snapshot;
        _capabilities = capabilities;
        _busy = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  void _stop() {
    _generation++;
    _gateway.cancelPending();
    setState(() => _busy = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    unawaited(
      guarded('[PHANTOM] close device inspection', () async {
        await _watch?.cancel();
        await _gateway.close();
      }),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.phantomInspectionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.phantomInspectionPrivacy),
          const SizedBox(height: 16),
          Text(snapshot?.deviceId ?? l10n.phantomInspectionConnect),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy || snapshot?.rpcReady != true
                    ? null
                    : _inspect,
                child: Text(l10n.phantomInspectionRead),
              ),
              OutlinedButton(
                onPressed: _busy ? _stop : null,
                child: Text(l10n.phantomInspectionStop),
              ),
            ],
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(),
            ),
          if (_failed) Text(l10n.phantomInspectionFailed),
          if (snapshot != null && snapshot.protocolVersion != null)
            ListTile(
              title: Text(l10n.phantomInspectionProtocol),
              subtitle: Text(snapshot.protocolVersion!),
            ),
          if (snapshot?.externalStorage case final storage?)
            ListTile(
              title: const Text('/ext'),
              subtitle: Text(
                l10n.phantomInspectionStorage(
                  storage.freeBytes,
                  storage.totalBytes,
                ),
              ),
            ),
          if (snapshot != null) ...[
            for (final item in {
              ...snapshot.info,
              ...snapshot.power.map(
                (key, value) => MapEntry('power.$key', value),
              ),
            }.entries)
              ListTile(
                title: Text(item.key),
                subtitle: SelectableText(item.value),
              ),
            for (final issue in snapshot.issues.entries)
              ListTile(
                title: Text(issue.key),
                subtitle: Text(_issueLabel(issue.value)),
              ),
          ],
          if (_capabilities case final report?) ...[
            const Divider(),
            for (final item in report.entries.entries)
              ListTile(
                title: Text(item.key),
                subtitle: Text(_capabilityLabel(item.value.state)),
              ),
          ],
          const Divider(),
          Text(l10n.phantomInspectionBridge),
        ],
      ),
    );
  }

  String _issueLabel(DeviceReadIssue issue) => switch (issue) {
    DeviceReadIssue.unsupported => context.l10n.phantomUnsupported,
    DeviceReadIssue.unavailable => context.l10n.phantomUnavailable,
    DeviceReadIssue.timedOut => context.l10n.phantomTimedOut,
    DeviceReadIssue.invalidResponse => context.l10n.phantomInvalidResponse,
  };

  String _capabilityLabel(CapabilityState state) => switch (state) {
    CapabilityState.supported => context.l10n.phantomObserved,
    CapabilityState.unsupported => context.l10n.phantomUnsupported,
    CapabilityState.unverified => context.l10n.phantomUnverified,
    CapabilityState.bridgeRequired => context.l10n.phantomInspectionBridge,
    CapabilityState.requiresExtension => context.l10n.phantomExtensionRequired,
  };
}
