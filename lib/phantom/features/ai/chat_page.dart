import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/guarded.dart';
import '../../../services/localization/l10n.dart';
import '../../ai/credentials.dart';
import '../../ai/openrouter.dart';
import '../../ai/read_only_agent.dart';
import '../../ai/observation.dart';
import '../../device/device_gateway.dart';
import 'observation_card.dart';

class PhantomChatPage extends StatefulWidget {
  const PhantomChatPage({
    super.key,
    required this.createGateway,
    this.credentials = const KeychainCredentialStore(),
    this.createProvider,
    this.loadModels,
  });
  final DeviceGateway Function() createGateway;
  final CredentialStore credentials;
  final AiProvider Function()? createProvider;
  final Future<List<ModelChoice>> Function()? loadModels;
  @override
  State<PhantomChatPage> createState() => _PhantomChatPageState();
}

class _PhantomChatPageState extends State<PhantomChatPage>
    with WidgetsBindingObserver {
  late final DeviceGateway _gateway;
  late final ReadOnlyAgent _agent;
  final _key = TextEditingController();
  final _input = TextEditingController();
  final _messages =
      <({bool user, String text, List<AgentObservation> observations})>[];
  List<ModelChoice> _models = [];
  String? _model;
  bool _saved = false;
  bool _busy = false;
  bool _loadingModels = false;
  bool _shareStatus = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gateway = widget.createGateway();
    _agent = ReadOnlyAgent(
      gateway: _gateway,
      credentials: widget.credentials,
      createProvider: widget.createProvider ?? () => OpenRouterProvider(),
    );
    unawaited(
      guarded(
        '[PHANTOM AI] read credential availability',
        _loadCredentialState,
      ),
    );
  }

  Future<void> _loadCredentialState() async {
    try {
      final saved =
          (await widget.credentials.read().timeout(const Duration(seconds: 5)))
              ?.isNotEmpty ==
          true;
      if (mounted) setState(() => _saved = saved);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.phantomAiStorageFailed);
    }
  }

  Future<void> _saveKey() async {
    try {
      await widget.credentials
          .write(_key.text.trim())
          .timeout(const Duration(seconds: 5));
      _key.clear();
      if (mounted) {
        setState(() {
          _saved = true;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.phantomAiStorageFailed);
    }
  }

  Future<void> _eraseKey() async {
    _stop();
    try {
      await widget.credentials.erase().timeout(const Duration(seconds: 5));
      _key.clear();
      if (mounted) {
        setState(() {
          _saved = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.phantomAiStorageFailed);
    }
  }

  Future<void> _loadModels() async {
    setState(() {
      _loadingModels = true;
      _error = null;
    });
    try {
      final models = await (widget.loadModels ?? loadOpenRouterModels)();
      if (mounted) {
        setState(() {
          _models = models;
          _model = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.phantomAiFailed);
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _send() async {
    final model = _model;
    final text = _input.text.trim();
    if (_busy || model == null || text.isEmpty) return;
    final generation = ++_generation;
    final shareStatus = _shareStatus;
    _input.clear();
    setState(() {
      _busy = true;
      _shareStatus = false;
      _error = null;
      _messages.add((user: true, text: text, observations: const []));
    });
    try {
      final answer = await _agent.send(
        text,
        model: model,
        shareDeviceStatus: shareStatus,
      );
      if (mounted && generation == _generation) {
        setState(() {
          _messages.add((
            user: false,
            text: answer,
            observations: _agent.observations,
          ));
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          if (_agent.observations.isNotEmpty) {
            _messages.add((
              user: false,
              text: '',
              observations: _agent.observations,
            ));
          }
          _error = context.l10n.phantomAiFailed;
          _busy = false;
        });
      }
    }
    while (_messages.length > 20) {
      _messages.removeRange(0, 2);
    }
  }

  void _stop() {
    _generation++;
    _agent.stop();
    if (mounted) setState(() => _busy = false);
  }

  void _eraseChat() {
    _stop();
    _agent.eraseConversation();
    setState(() {
      _messages.clear();
      _shareStatus = false;
      _error = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _agent.stop();
    _key.dispose();
    _input.dispose();
    unawaited(guarded('[PHANTOM AI] close device gateway', _gateway.close));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.phantomAiTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.phantomAiPrivacy),
          const SizedBox(height: 16),
          if (_saved) Text(l10n.phantomAiKeySaved),
          TextField(
            controller: _key,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 512,
            decoration: InputDecoration(labelText: l10n.phantomAiKey),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _busy ? null : _saveKey,
                child: Text(l10n.phantomAiSaveKey),
              ),
              TextButton(
                onPressed: _eraseKey,
                child: Text(l10n.phantomAiEraseKey),
              ),
              TextButton(
                onPressed: _loadingModels || _busy ? null : _loadModels,
                child: Text(l10n.phantomAiLoadModels),
              ),
            ],
          ),
          if (_loadingModels) const LinearProgressIndicator(),
          if (_models.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey(_models),
              initialValue: _model,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.phantomAiModel),
              items: [
                for (final model in _models)
                  DropdownMenuItem(
                    value: model.id,
                    child: Text(model.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (model) => setState(() => _model = model),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.phantomAiShareStatus),
            value: _shareStatus,
            onChanged: _busy
                ? null
                : (value) => setState(() => _shareStatus = value),
          ),
          Text(l10n.phantomAiBudget),
          const Divider(),
          for (final message in _messages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.user
                        ? l10n.phantomAiYou
                        : message.text.isEmpty
                        ? l10n.phantomNoAiExplanation
                        : l10n.phantomAiExplanation,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (message.text.isNotEmpty) SelectableText(message.text),
                  for (final observation in message.observations)
                    ObservationCard(observation: observation),
                  if (!message.user && message.observations.isEmpty)
                    Text(l10n.phantomNoObservations),
                ],
              ),
            ),
          if (_error != null) Text(_error!),
          TextField(
            controller: _input,
            maxLength: 2000,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.phantomAiMessage),
          ),
          if (_busy) const LinearProgressIndicator(),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _busy || !_saved || _model == null ? null : _send,
                child: Text(l10n.phantomAiSend),
              ),
              OutlinedButton(
                onPressed: _busy ? _stop : null,
                child: Text(l10n.phantomAiStop),
              ),
              TextButton(
                onPressed: _eraseChat,
                child: Text(l10n.phantomAiEraseChat),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
