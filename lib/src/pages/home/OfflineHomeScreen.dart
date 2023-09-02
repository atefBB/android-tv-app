import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mawaqit/const/resource.dart';
import 'package:mawaqit/i18n/l10n.dart';
import 'package:mawaqit/src/enum/home_active_screen.dart';
import 'package:mawaqit/src/helpers/AppRouter.dart';
import 'package:mawaqit/src/helpers/RelativeSizes.dart';
import 'package:mawaqit/src/pages/ErrorScreen.dart';
import 'package:mawaqit/src/pages/MosqueSearchScreen.dart';
import 'package:mawaqit/src/pages/home/sub_screens/AnnouncementScreen.dart';
import 'package:mawaqit/src/pages/home/widgets/mosque_background_screen.dart';
import 'package:mawaqit/src/pages/home/widgets/workflows/repeating_workflow_widget.dart';
import 'package:mawaqit/src/pages/home/workflow/jumua_workflow_screen.dart';
import 'package:mawaqit/src/pages/home/workflow/normal_workflow.dart';
import 'package:mawaqit/src/pages/home/workflow/salah_workflow.dart';
import 'package:mawaqit/src/services/mosque_manager.dart';
import 'package:mawaqit/src/services/user_preferences_manager.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../HomeScreen.dart';

class OfflineHomeScreen extends StatelessWidget {
  OfflineHomeScreen({Key? key}) : super(key: key);

  Future<bool?> showClosingDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text(S.of(context).closeApp),
        content: new Text(S.of(context).sureCloseApp),
        actions: <Widget>[
          new TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text(S.of(context).cancel),
          ),
          SizedBox(height: 16),
          new TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: new Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }

  /// todo register this each day at 00:00
  Widget activeWorkflow(MosqueManager mosqueManager) {
    final now = mosqueManager.mosqueDate();
    final isFriday = now.weekday == DateTime.friday;

    final times = mosqueManager.useTomorrowTimes ? mosqueManager.actualTimes(now.add(1.days)) : mosqueManager.actualTimes(now);

    final iqama =
        mosqueManager.useTomorrowTimes ? mosqueManager.actualIqamaTimes(now.add(1.days)) : mosqueManager.actualIqamaTimes(now);

    return RepeatingWorkFlowWidget(
      child: NormalWorkflowScreen(),
      items: [
        ...times.mapIndexed((index, elem) => RepeatingWorkflowItem(
              builder: (context, next) => SalahWorkflowScreen(onDone: next),
              repeatingDuration: 1.days,

              dateTime: elem,

              /// auto start Workflow if user starts the app during the Salah time
              /// give 4 minute for the salah and 2 for azkar
              showInitial: () => now.isAfter(elem) && now.isBefore(iqama[index].add(6.minutes)),

              // dateTime: e,
              // disable Duhr if it's Friday
              disabled: index == 1 && isFriday,
            )),

        // Jumuaa Workflow
        RepeatingWorkflowItem(
          builder: (context, next) => JumuaaWorkflowScreen(onDone: next),
          repeatingDuration: 7.days,
          dateTime: mosqueManager.activeJumuaaDate(),
          showInitial: () {
            final activeJumuaaDate = mosqueManager.activeJumuaaDate();

            if (now.isBefore(activeJumuaaDate)) return false;

            /// If user opens the app during the Jumuaa time then show the Jumuaa workflow
            /// give 30 minutes for the Jumuaa
            return now.isAfter(activeJumuaaDate.add(Duration(minutes: mosqueManager.mosqueConfig!.jumuaTimeout ?? 30)));
          },
        )
      ],
    );
  }

  /// show online home if enabled
  /// show announcement mode if enabled
  /// show offline home if enabled
  Widget activeHomeScreen(
    MosqueManager mosqueManager,
    bool onlineMode,
    bool announcementMode,
  ) {
    if (onlineMode) return HomeScreen();

    if (announcementMode) return AnnouncementScreen();

    return activeWorkflow(mosqueManager);
  }

  @override
  Widget build(BuildContext context) {
    RelativeSizes.instance.size = MediaQuery.of(context).size;
    final mosqueProvider = context.watch<MosqueManager>();
    final userPrefs = context.watch<UserPreferencesManager>();

    if (!mosqueProvider.loaded)
      return ErrorScreen(
        title: S.of(context).reset,
        description: S.of(context).mosqueNotFoundMessage,
        image: R.ASSETS_IMG_ICON_EXIT_PNG,
        onTryAgain: () => AppRouter.push(MosqueSearchScreen()),
        tryAgainText: S.of(context).changeMosque,
      );

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          return false;
        }

        return await showClosingDialog(context) ?? false;
      },
      child: MosqueBackgroundScreen(
        key: ValueKey(mosqueProvider.mosque?.uuid),
        child: SafeArea(
          bottom: true,
          child: activeHomeScreen(
            mosqueProvider,
            userPrefs.webViewMode,
            userPrefs.announcementsOnly,
          ),
        ),
      ),
    );
  }
}
