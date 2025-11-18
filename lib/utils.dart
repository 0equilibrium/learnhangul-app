import 'models.dart';

/// Minimum number of correct answers per character required to unlock
/// the next row of Hangul blocks.
const int kRowUnlockThreshold = 4;

/// Holds unlock information for a single Hangul section (row).
class SectionUnlockStatus {
  const SectionUnlockStatus({
    required this.section,
    required this.index,
    required this.isUnlocked,
    required this.isMastered,
    required this.minCorrect,
  });

  final HangulSection section;
  final int index;
  final bool isUnlocked;
  final bool isMastered;
  final int minCorrect;
}

/// Aggregated information about unlock progress across multiple sections.
class SectionUnlockSummary {
  const SectionUnlockSummary({required this.statuses, required this.threshold});

  final List<SectionUnlockStatus> statuses;
  final int threshold;

  /// Returns the sections that are currently available for practice.
  List<HangulSection> get unlockedSections => statuses
      .where((status) => status.isUnlocked)
      .map((status) => status.section)
      .toList(growable: false);

  /// Returns the sections that should be included in training sessions.
  ///
  /// Includes all unlocked rows plus the current in-progress row even if it
  /// hasn't fully met the threshold yet. This avoids situations where only
  /// previously mastered rows are surfaced during 훈련하기.
  List<HangulSection> get trainableSections {
    final sections = unlockedSections.toList(growable: true);
    SectionUnlockStatus? inProgress;
    for (final status in statuses) {
      if (status.isUnlocked && !status.isMastered) {
        inProgress = status;
        break;
      }
    }
    SectionUnlockStatus? fallbackLocked;
    if (inProgress == null) {
      for (final status in statuses) {
        if (!status.isUnlocked) {
          fallbackLocked = status;
          break;
        }
      }
    }
    final candidate = inProgress ?? fallbackLocked;
    if (candidate != null &&
        !sections.any((section) => identical(section, candidate.section))) {
      sections.add(candidate.section);
    }
    return sections;
  }

  /// All sections have been mastered (i.e. met the threshold).
  bool get allMastered =>
      statuses.isNotEmpty && statuses.every((status) => status.isMastered);

  /// The final section is available for study (even if not yet mastered).
  bool get allUnlocked => statuses.isNotEmpty && statuses.last.isUnlocked;

  /// Convenience getter exposing the list length to avoid null checks.
  int get length => statuses.length;

  SectionUnlockStatus? statusForSection(HangulSection section) {
    for (final status in statuses) {
      if (identical(status.section, section)) {
        return status;
      }
    }
    return null;
  }
}

SectionUnlockSummary evaluateSectionUnlocks({
  required List<HangulSection> sections,
  required Map<String, int> correctCounts,
  int threshold = kRowUnlockThreshold,
}) {
  final statuses = <SectionUnlockStatus>[];
  var previousSectionsMastered = true;

  for (var i = 0; i < sections.length; i++) {
    final section = sections[i];
    final minCorrect = _minCorrectInSection(section, correctCounts);
    final isUnlocked = previousSectionsMastered;
    final isMastered = isUnlocked && minCorrect >= threshold;
    statuses.add(
      SectionUnlockStatus(
        section: section,
        index: i,
        isUnlocked: isUnlocked,
        isMastered: isMastered,
        minCorrect: minCorrect,
      ),
    );
    previousSectionsMastered = isMastered;
  }

  return SectionUnlockSummary(statuses: statuses, threshold: threshold);
}

int _minCorrectInSection(
  HangulSection section,
  Map<String, int> correctCounts,
) {
  if (section.characters.isEmpty) {
    return 0;
  }

  var minCorrect = correctCounts[section.characters.first.symbol] ?? 0;
  for (final character in section.characters.skip(1)) {
    final count = correctCounts[character.symbol] ?? 0;
    if (count < minCorrect) {
      minCorrect = count;
    }
  }
  return minCorrect;
}
