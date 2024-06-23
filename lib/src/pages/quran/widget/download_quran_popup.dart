import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/i18n/l10n.dart';
import 'package:mawaqit/src/state_management/quran/download_quran/download_quran_notifier.dart';
import 'package:mawaqit/src/state_management/quran/download_quran/download_quran_state.dart';
import 'package:mawaqit/src/state_management/quran/reading/quran_reading_state.dart';

Future<void> showDownloadQuranAlertDialog(BuildContext context, WidgetRef ref) async {
  MoshafType selectedMoshafType = MoshafType.hafs;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(S.of(context).chooseQuranType),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<MoshafType>(
                  title: Text(S.of(context).warsh),
                  value: MoshafType.warsh,
                  groupValue: selectedMoshafType,
                  onChanged: (MoshafType? value) {
                    setState(() {
                      if (value != null) {
                        selectedMoshafType = value;
                      }
                    });
                  },
                ),
                RadioListTile<MoshafType>(
                  title: Text(S.of(context).hafs),
                  value: MoshafType.hafs,
                  groupValue: selectedMoshafType,
                  onChanged: (MoshafType? value) {
                    log('quran: ui: $value');
                    setState(() {
                      if (value != null) {
                        selectedMoshafType = value;
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.of(context).cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await startQuranDownload(context, ref, selectedMoshafType);
                },
                child: Text(S.of(context).download),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> startQuranDownload(BuildContext context, WidgetRef ref, MoshafType moshafType) async {
  await ref.read(downloadQuranNotifierProvider.notifier).checkForUpdate(moshafType);
  final state = ref.read(downloadQuranNotifierProvider);

  state.whenOrNull(
    data: (data) async {
      if (data is UpdateAvailable) {
        final shouldDownload = await _showConfirmationDialog(context);
        if (shouldDownload) {
          ref.read(downloadQuranNotifierProvider.notifier).download(moshafType);
          await _showDownloadProgressDialog(context, ref);
        }
      } else if (data is NoUpdate) {
        await _alreadyUpdatedVersion(context, ref);
      }
    },
    error: (error, stackTrace) async {
      _buildErrorPopup(context, error);
    },
  );
}

Future<bool> _showConfirmationDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(S.of(context).downloadQuran),
        content: Text(S.of(context).askDownloadQuran),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).download),
          ),
        ],
      );
    },
  );
}

Future<void> _showDownloadProgressDialog(BuildContext context, WidgetRef ref) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Consumer(
        builder: (context, ref, _) {
          final downloadQuranState = ref.watch(downloadQuranNotifierProvider);
          return downloadQuranState.when(
            data: (state) {
              if (state is Downloading) {
                return _buildDownloadingPopup(context, state.progress, ref);
              } else if (state is Extracting) {
                return _buildExtractingPopup(context, state.progress);
              } else if (state is Success) {
                return _buildSuccessPopup(context, state.version);
              } else {
                Navigator.pop(context);
                return Container();
              }
            },
            loading: () => _buildCheckingPopup(context),
            error: (error, stackTrace) => _buildErrorPopup(context, error),
          );
        },
      );
    },
  );
}

Future<bool> _showFirstTimePopup(BuildContext context) async {
  return await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(S.of(context).downloadQuran),
        content: Text(S.of(context).askDownloadQuran),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).download),
          ),
        ],
      );
    },
  );
}

Widget _buildCheckingPopup(BuildContext context) {
  return AlertDialog(
    alignment: Alignment.center,
    content: CircularProgressIndicator(
      color: Theme.of(context).primaryColor,
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(S.of(context).cancel),
      ),
    ],
  );
}

Widget _buildDownloadingPopup(BuildContext context, double progress, WidgetRef ref) {
  return AlertDialog(
    title: Text(S.of(context).downloadingQuran),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress / 100,
        ),
        const SizedBox(height: 8),
        Text('${(progress).toStringAsFixed(2)}%'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          ref.read(downloadQuranNotifierProvider.notifier).cancelDownload();
          Navigator.pop(context);
        },
        child: Text(S.of(context).cancel),
      ),
    ],
  );
}


Widget _buildExtractingPopup(BuildContext context, double progress) {
  return AlertDialog(
    title: Text(S.of(context).extractingQuran),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress / 100,
        ),
        const SizedBox(height: 8),
        Text('${progress.toStringAsFixed(2)}%'),
      ],
    ),
  );
}

Widget _buildSuccessPopup(BuildContext context, String version) {
  return AlertDialog(
    title: Text(S.of(context).quranIsUpdated),
    content: Text(S.of(context).quranUpdatedVersion(version)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(S.of(context).ok),
      ),
    ],
  );
}

Widget _buildErrorPopup(BuildContext context, Object error) {
  return AlertDialog(
    title: Text(S.of(context).error),
    content: Text('An error occurred: $error'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(S.of(context).ok),
      ),
    ],
  );
}

Future<void> _alreadyUpdatedVersion(BuildContext context, WidgetRef ref) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(S.of(context).quranIsUpdated),
        content: Text(S.of(context).quranIsAlreadyDownloaded),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).ok),
          ),
        ],
      );
    },
  );
}
