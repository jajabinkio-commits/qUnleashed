import 'package:flutter/material.dart';

import '../../services/guarded.dart';
import '../../services/localization/l10n.dart';
import '../../services/telemetry/settings.dart';
import '../../theme/theme.dart';

/// Explains the opt-in controls once. Dismissal never enables diagnostics;
/// the user must separately enable reports/replay in Settings.
Future<void> showDiagnosticsNoticeIfDue(
  BuildContext context,
  DiagnosticsSettings settings,
) async {
  // The read is awaited rather than assumed: this runs on the first frame,
  // which can be ahead of the store opening. `load` memoises, so the switch
  // row asking later costs nothing.
  await settings.load();
  if (settings.noticeShown) return;
  if (!context.mounted) return;

  // Recording a notice as shown is separate from granting consent.
  await guarded(
    '[Diagnostics] recording that the notice was shown',
    settings.markNoticeShown,
  );
  if (!context.mounted) return;

  final turnOff = await showModalBottomSheet<bool>(
    context: context,
    // Dismissible, which is the whole difference between this and a gate.
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _DiagnosticsNoticeSheet(),
  );
  if (turnOff != true) return;
  await settings.setShareLogs(false);
}

class _DiagnosticsNoticeSheet extends StatelessWidget {
  const _DiagnosticsNoticeSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          color: colors.dialogBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.diagnosticsNoticeTitle,
              style: TextStyle(
                color: colors.dialogText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            // Scrollable, and `Flexible` so it gives way rather than the
            // buttons. The body grew by one sentence - that a screen
            // recording goes with a report - and overflowed by 15px on a
            // short window, which took two unrelated tests down with it: the
            // notice is raised over the app on first launch, so a layout
            // exception here lands in whatever else was being pumped.
            //
            // Every translation of this is longer than the English, and §1
            // makes this the one screen that has to be readable for the
            // notice to be a notice. A fixed column cannot promise that;
            // scrolling can.
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  context.l10n.diagnosticsNoticeBody,
                  style: TextStyle(
                    color: colors.dialogText,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    context.l10n.diagnosticsNoticeTurnOff,
                    style: TextStyle(color: colors.dialogMuted),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    context.l10n.commonGotIt,
                    style: TextStyle(color: colors.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
