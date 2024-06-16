import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/src/data/repository/quran/quran_download_impl.dart';
import 'package:mawaqit/src/domain/error/quran_exceptions.dart';
import 'package:mawaqit/src/helpers/quran_path_helper.dart';
import 'package:mawaqit/src/state_management/quran/download_quran/download_quran_state.dart';
import 'package:mawaqit/src/state_management/quran/reading/quran_reading_state.dart';
import 'package:path_provider/path_provider.dart';

class DownloadQuranNotifier extends AsyncNotifier<DownloadQuranState> {
  @override
  FutureOr<DownloadQuranState> build() {
    return Initial();
  }

  /// [checkForUpdate] checks for the Quran update
  ///
  /// If the Quran is not downloaded or the remote version is different from the local version,
  Future<void> checkForUpdate() async {
    try {
      state = AsyncLoading();

      final downloadQuranRepoImpl = await ref.read(quranDownloadRepositoryProvider(MoshafType.warsh).future);
      final localVersion = await downloadQuranRepoImpl.getLocalQuranVersion();
      final remoteVersion = await downloadQuranRepoImpl.getRemoteQuranVersion();

      if (localVersion == null || remoteVersion != localVersion) {
        state = AsyncData(UpdateAvailable(remoteVersion));
      } else {
        final savePath = await getApplicationSupportDirectory();
        final quranPathHelper = QuranPathHelper(
          applicationSupportDirectory: savePath,
          moshafType: MoshafType.warsh,
        );
        state = AsyncData(
          NoUpdate(
            version: remoteVersion,
            svgFolderPath: quranPathHelper.quranDirectoryPath,
          ),
        );
      }
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  /// [download] downloads the Quran and extracts it
  Future<void> download() async {
    try {
      // Notify that the update check has started
      state = AsyncLoading();

      final downloadQuranRepoImpl = await ref.read(quranDownloadRepositoryProvider(MoshafType.warsh).future);
      final localVersion = await downloadQuranRepoImpl.getLocalQuranVersion();
      final remoteVersion = await downloadQuranRepoImpl.getRemoteQuranVersion();

      if (localVersion == null || remoteVersion != localVersion) {
        // Notify that the download has started
        state = AsyncData(Downloading(0));

        // Download the Quran
        await downloadQuranRepoImpl.downloadQuran(
          version: remoteVersion,
          moshafType: MoshafType.warsh,
          onReceiveProgress: (progress) {
            state = AsyncData(Downloading(progress));
          },
          onExtractProgress: (progress) {
            state = AsyncData(Extracting(progress));
          },
        );
        final savePath = await getApplicationSupportDirectory();

        final quranPathHelper = QuranPathHelper(
          applicationSupportDirectory: savePath,
          moshafType: MoshafType.warsh,
        );
        // Notify the success state with the new version
        state = AsyncData(
          Success(
            version: remoteVersion,
            svgFolderPath: quranPathHelper.quranDirectoryPath,
          ),
        );
      } else {
        final savePath = await getApplicationSupportDirectory();
        final svgFolderPath = '${savePath.path}/quran';
        state = AsyncData(
          NoUpdate(
            version: remoteVersion,
            svgFolderPath: svgFolderPath,
          ),
        );
      }
    } on CancelDownloadException catch (e, s) {
      state = AsyncData(CancelDownload());
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  /// [cancelDownload] cancels the download
  Future<void> cancelDownload() async {
    try {
      state = AsyncLoading();
      final downloadQuranRepoImpl = await ref.read(quranDownloadRepositoryProvider(MoshafType.warsh).future);
      downloadQuranRepoImpl.cancelDownload();
      state = AsyncData(CancelDownload());
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

final downloadQuranNotifierProvider =
    AsyncNotifierProvider<DownloadQuranNotifier, DownloadQuranState>(DownloadQuranNotifier.new);
