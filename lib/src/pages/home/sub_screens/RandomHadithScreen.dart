import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/src/helpers/Api.dart';
import 'package:mawaqit/src/helpers/PerformanceHelper.dart';
import 'package:mawaqit/src/helpers/RelativeSizes.dart';
import 'package:mawaqit/src/pages/home/widgets/AboveSalahBar.dart';
import 'package:mawaqit/src/pages/home/widgets/HadithScreen.dart';
import 'package:mawaqit/src/pages/home/widgets/salah_items/responsive_mini_salah_bar_widget.dart';
import 'package:provider/provider.dart';

import '../../../helpers/StringUtils.dart';
import '../../../services/mosque_manager.dart';
import '../../../state_management/random_hadith/random_hadith_notifier.dart';

class RandomHadithScreen extends ConsumerStatefulWidget {
  const RandomHadithScreen({Key? key, this.onDone}) : super(key: key);

  final VoidCallback? onDone;

  @override
  ConsumerState<RandomHadithScreen> createState() => _RandomHadithScreenState();
}

class _RandomHadithScreenState extends ConsumerState<RandomHadithScreen> {
  String? hadith;

  @override
  void initState() {
    final mosqueManager = context.read<MosqueManager>();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      ref.read(randomHadithNotifierProvider.notifier).getRandomHadith(
            language: mosqueManager.mosqueConfig!.hadithLang ?? 'ar',
          );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mosqueManager = context.watch<MosqueManager>();
    final hadithState = ref.watch(randomHadithNotifierProvider);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: AboveSalahBar(),
        ),
        Expanded(
          // child: HadithWidget(
          //   translatedText: context.watch<MosqueManager>().hadith,
          //   textDirection: StringManager.getTextDirectionOfLocal(
          //     Locale(mosqueManager.mosqueConfig!.hadithLang ?? 'en'),
          //   ),
          // ),
          child: hadithState.when(
            data: (hadith) {
              return HadithWidget(
                translatedText: hadith.hadith,
                textDirection: StringManager.getTextDirectionOfLocal(
                  Locale(mosqueManager.mosqueConfig!.hadithLang ?? 'en'),
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) {
              widget.onDone?.call();
              return Center(
              child: Text('Error: $error'),
            );
            },
          ),
        ),
        ResponsiveMiniSalahBarWidget(),
        SizedBox(height: 4.vh),
      ],
    );
  }
}
