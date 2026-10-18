import 'package:flutter/material.dart';

import '../../../services/localization/l10n.dart';
import '../../../components/sensitive_surface.dart';
import '../../ai/credentials.dart';
import '../../ai/openrouter.dart';
import '../../ai/screen_interpreter.dart';

class PhantomScreenPage extends StatefulWidget with SensitiveSurface {
  const PhantomScreenPage({
    super.key,
    required this.screen,
    this.credentials = const KeychainCredentialStore(),
    this.createProvider,
    this.loadModels,
  });
  final ScreenAttachment screen;
  final CredentialStore credentials;
  final AiProvider Function()? createProvider;
  final Future<List<ModelChoice>> Function()? loadModels;
  @override
  State<PhantomScreenPage> createState() => _PhantomScreenPageState();
}

class _PhantomScreenPageState extends State<PhantomScreenPage>
    with WidgetsBindingObserver {
  late final ScreenInterpreter _interpreter;
  List<ModelChoice> _models = [];
  ModelChoice? _model;
  bool _consent = false;
  bool _busy = false;
  bool _loading = false;
  int _generation = 0;
  String? _answer;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _interpreter = ScreenInterpreter(
      credentials: widget.credentials,
      createProvider: widget.createProvider ?? () => OpenRouterProvider(),
    );
  }

  Future<void> _modelsForVision() async {
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final models =
          await (widget.loadModels ??
              () => loadOpenRouterModels(visionOnly: true))();
      if (mounted && generation == _generation) {
        setState(() {
          _models = models.where((m) => m.supportsImages).toList();
          _model = null;
          if (_models.isEmpty) _error = context.l10n.phantomScreenNoModels;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = context.l10n.phantomAiFailed);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _explain() async {
    if (_busy || !_consent || _model == null) return;
    final generation = ++_generation;
    final model = _model!;
    setState(() {
      _busy = true;
      _consent = false;
      _answer = null;
      _error = null;
    });
    try {
      final answer = await _interpreter.explain(
        widget.screen,
        model: model,
        consent: true,
      );
      if (mounted && generation == _generation) {
        setState(() {
          _answer = answer;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = context.l10n.phantomScreenFailed;
          _busy = false;
        });
      }
    }
  }

  void _stop() {
    _generation++;
    _interpreter.stop();
    if (mounted) {
      setState(() {
        _busy = false;
        _loading = false;
        _consent = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _interpreter.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.phantomScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.phantomScreenPrivacy),
          const SizedBox(height: 12),
          Text(
            l10n.phantomObservedAt(
              widget.screen.capturedAt.toLocal().toIso8601String(),
            ),
          ),
          const SizedBox(height: 12),
          Image.memory(
            widget.screen.png,
            height: 180,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
          TextButton(
            onPressed: _busy || _loading ? null : _modelsForVision,
            child: Text(l10n.phantomAiLoadModels),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_models.isNotEmpty)
            DropdownButtonFormField<ModelChoice>(
              key: ValueKey(_models),
              initialValue: _model,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.phantomAiModel),
              items: [
                for (final model in _models)
                  DropdownMenuItem(
                    value: model,
                    child: Text(model.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (model) => setState(() => _model = model),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.phantomScreenConsent),
            value: _consent,
            onChanged: _busy
                ? null
                : (value) => setState(() => _consent = value),
          ),
          Text(l10n.phantomScreenBudget),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _busy || !_consent || _model == null
                    ? null
                    : _explain,
                child: Text(l10n.phantomScreenSend),
              ),
              TextButton(onPressed: _stop, child: Text(l10n.phantomAiStop)),
              TextButton(
                onPressed: () {
                  _stop();
                  setState(() {
                    _answer = null;
                    _error = null;
                  });
                },
                child: Text(l10n.phantomAiEraseChat),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!),
          if (_answer != null) ...[
            const Divider(),
            Text(
              l10n.phantomScreenInference,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(_answer!),
          ],
        ],
      ),
    );
  }
}
