import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mawaqit/src/enum/home_active_screen.dart';
import 'package:mawaqit/src/helpers/HexColor.dart';
import 'package:mawaqit/src/pages/home/workflow/jumua_workflow_screen.dart';
import 'package:mawaqit/src/pages/home/workflow/normal_workflow.dart';
import 'package:mawaqit/src/pages/home/workflow/salah_workflow.dart';
import 'package:mawaqit/src/services/mosque_manager.dart';
import 'package:mawaqit/src/widgets/MawaqitDrawer.dart';
import 'package:provider/provider.dart';

class OfflineHomeScreen extends StatelessWidget {
  OfflineHomeScreen({Key? key}) : super(key: key);

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget activeWorkflow(MosqueManager mosqueManager) {
    switch (mosqueManager.workflow) {
      case HomeActiveWorkflow.normal:
        return NormalWorkflowScreen();
      case HomeActiveWorkflow.salah:
        return SalahWorkflowScreen(onDone: mosqueManager.backToNormalHomeScreen);
      case HomeActiveWorkflow.jumuaa:
        return JumuaaWorkflowScreen(onDone: mosqueManager.backToNormalHomeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mosqueProvider = context.watch<MosqueManager>();
    final mosqueConfig = mosqueProvider.mosqueConfig;

    if (mosqueProvider.mosque == null || mosqueProvider.times == null || mosqueProvider.mosqueConfig == null)
      return SizedBox();

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.arrowLeft): () => _scaffoldKey.currentState?.openDrawer(),
        SingleActivator(LogicalKeyboardKey.arrowRight): () => _scaffoldKey.currentState?.openDrawer(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: MawaqitDrawer(goHome: () => Navigator.pop(context)),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: mosqueConfig!.backgroundType == "color"
                ? BoxDecoration(
                    color: HexColor(
                    mosqueConfig.backgroundColor,
                  ))
                : BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://mawaqit.net/bundles/app/prayer-times/img/background/${mosqueConfig.backgroundMotif ?? 5}.jpg"),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {},
                    ),
                  ),
            child: Container(
              child: activeWorkflow(mosqueProvider),
            ),
          ),
        ),
      ),
    );
  }
}
