import 'package:equatable/equatable.dart';
import 'package:mawaqit/src/domain/model/quran/moshaf_model.dart';

import 'package:mawaqit/src/domain/model/quran/reciter_model.dart';

import 'package:mawaqit/src/domain/model/quran/surah_model.dart';

class ReciteState extends Equatable {
  final List<ReciterModel> reciters;
  final ReciterModel? selectedReciter;
  final MoshafModel? selectedMoshaf;
  final List<ReciterModel> searchReciters;
  ReciteState({
    required this.reciters,
    this.selectedReciter,
    this.selectedMoshaf,
    this.searchReciters = const [],
  });

  ReciteState copyWith({
    List<ReciterModel>? reciters,
    ReciterModel? selectedReciter,
    MoshafModel? selectedMoshaf,
    List<ReciterModel>? searchReciters,
  }) {
    return ReciteState(
      reciters: reciters ?? this.reciters,
      selectedReciter: selectedReciter ?? this.selectedReciter,
      selectedMoshaf: selectedMoshaf ?? this.selectedMoshaf,
      searchReciters: searchReciters ?? this.searchReciters,
    );
  }

  @override
  String toString() {
    return 'ReciteState(reciters: ${reciters.length}) selectedReciter: ${selectedReciter} selectedMoshaf: ${selectedMoshaf}'
        '| searchReciters: ${searchReciters.length})';
  }

  @override
  List<Object?> get props => [reciters, selectedMoshaf, selectedReciter, searchReciters];
}
