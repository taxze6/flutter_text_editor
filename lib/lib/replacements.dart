import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

///这个函数接受一个String，用于替换选择的字符串和一个[TextRange]
typedef InlineSpanGenerator = InlineSpan Function(String, TextRange);

class TextEditingInlineSpanReplacement {
  /// 需要替换的区间
  TextRange range;

  /// 返回每个匹配返回[InlineSpan]实例的函数
  InlineSpanGenerator generator;

  bool expand;

  bool? isWidget;

  TextEditingInlineSpanReplacement(this.range, this.generator, this.expand,
      {this.isWidget});

  TextEditingInlineSpanReplacement? onDelete(TextEditingDeltaDeletion delta) {
    final TextRange deletedRange = delta.deletedRange;
    final int deletedLength = delta.textDeleted.length;

    if (range.start >= deletedRange.start &&
        (range.start < deletedRange.end && range.end > deletedRange.end)) {
      return copy(
        range: TextRange(
          start: deletedRange.end - deletedLength,
          end: range.end - deletedLength,
        ),
      );
    } else if ((range.start < deletedRange.start &&
            range.end > deletedRange.start) &&
        range.end <= deletedRange.end) {
      return copy(
        range: TextRange(
          start: range.start,
          end: deletedRange.start,
        ),
      );
    } else if (range.start < deletedRange.start &&
        range.end > deletedRange.end) {
      return copy(
        range: TextRange(
          start: range.start,
          end: range.end - deletedLength,
        ),
      );
    } else if (range.start >= deletedRange.start &&
        range.end <= deletedRange.end) {
      return null;
    } else if (range.start > deletedRange.start &&
        range.start >= deletedRange.end) {
      return copy(
        range: TextRange(
          start: range.start - deletedLength,
          end: range.end - deletedLength,
        ),
      );
    } else if (range.end <= deletedRange.start &&
        range.end < deletedRange.end) {
      return copy(
        range: TextRange(
          start: range.start,
          end: range.end,
        ),
      );
    }

    return null;
  }

  TextEditingInlineSpanReplacement? onInsertion(
      TextEditingDeltaInsertion delta) {
    final int insertionOffset = delta.insertionOffset;
    final int insertedLength = delta.textInserted.length;

    if (range.end == insertionOffset) {
      if (expand) {
        return copy(
          range: TextRange(
            start: range.start,
            end: range.end + insertedLength,
          ),
        );
      } else {
        return copy(
          range: TextRange(
            start: range.start,
            end: range.end,
          ),
        );
      }
    }
    if (range.start < insertionOffset && range.end < insertionOffset) {
      return copy(
        range: TextRange(
          start: range.start,
          end: range.end,
        ),
      );
    } else if (range.start >= insertionOffset && range.end > insertionOffset) {
      return copy(
        range: TextRange(
          start: range.start + insertedLength,
          end: range.end + insertedLength,
        ),
      );
    } else if (range.start < insertionOffset && range.end > insertionOffset) {
      return copy(
        range: TextRange(
          start: range.start,
          end: range.end + insertedLength,
        ),
      );
    }
    return null;
  }

  TextEditingInlineSpanReplacement? onNonTextUpdate(
      TextEditingDeltaNonTextUpdate delta) {
    if (range.isCollapsed) {
      if (range.start != delta.selection.start &&
          range.end != delta.selection.end) {
        return null;
      }
    }
    return this;
  }

  List<TextEditingInlineSpanReplacement>? onReplacement(
      TextEditingDeltaReplacement delta) {
    final TextRange replacedRange = delta.replacedRange;
    final bool replacementShortenedText =
        delta.replacementText.length < delta.textReplaced.length;
    final bool replacementLengthenedText =
        delta.replacementText.length > delta.textReplaced.length;
    final bool replacementEqualLength =
        delta.replacementText.length == delta.textReplaced.length;
    final int changedOffset = replacementShortenedText
        ? delta.textReplaced.length - delta.replacementText.length
        : delta.replacementText.length - delta.textReplaced.length;

    if (range.start >= replacedRange.start &&
        (range.start < replacedRange.end && range.end > replacedRange.end)) {
      if (replacementShortenedText) {
        return [
          copy(
            range: TextRange(
              start: replacedRange.end - changedOffset,
              end: range.end - changedOffset,
            ),
          ),
        ];
      } else if (replacementLengthenedText) {
        return [
          copy(
            range: TextRange(
              start: replacedRange.end + changedOffset,
              end: range.end + changedOffset,
            ),
          ),
        ];
      } else if (replacementEqualLength) {
        return [
          copy(
            range: TextRange(
              start: replacedRange.end,
              end: range.end,
            ),
          ),
        ];
      }
    } else if ((range.start < replacedRange.start &&
            range.end > replacedRange.start) &&
        range.end <= replacedRange.end) {
      return [
        copy(
          range: TextRange(
            start: range.start,
            end: replacedRange.start,
          ),
        ),
      ];
    } else if (range.start < replacedRange.start &&
        range.end > replacedRange.end) {
      if (replacementShortenedText) {
        return [
          copy(
            range: TextRange(
              start: range.start,
              end: replacedRange.start,
            ),
          ),
          copy(
            range: TextRange(
              start: replacedRange.end - changedOffset,
              end: range.end - changedOffset,
            ),
          ),
        ];
      } else if (replacementLengthenedText) {
        return [
          copy(
            range: TextRange(
              start: range.start,
              end: replacedRange.start,
            ),
          ),
          copy(
            range: TextRange(
              start: replacedRange.end + changedOffset,
              end: range.end + changedOffset,
            ),
          ),
        ];
      } else if (replacementEqualLength) {
        return [
          copy(
            range: TextRange(
              start: range.start,
              end: replacedRange.start,
            ),
          ),
          copy(
            range: TextRange(
              start: replacedRange.end,
              end: range.end,
            ),
          ),
        ];
      }
    } else if (range.start >= replacedRange.start &&
        range.end <= replacedRange.end) {
      // remove attribute.
      return null;
    } else if (range.start > replacedRange.start &&
        range.start >= replacedRange.end) {
      if (replacementShortenedText) {
        return [
          copy(
            range: TextRange(
              start: range.start - changedOffset,
              end: range.end - changedOffset,
            ),
          ),
        ];
      } else if (replacementLengthenedText) {
        return [
          copy(
            range: TextRange(
              start: range.start + changedOffset,
              end: range.end + changedOffset,
            ),
          ),
        ];
      } else if (replacementEqualLength) {
        return [this];
      }
    } else if (range.end <= replacedRange.start &&
        range.end < replacedRange.end) {
      return [
        copy(
          range: TextRange(
            start: range.start,
            end: range.end,
          ),
        ),
      ];
    }

    return null;
  }

  List<TextEditingInlineSpanReplacement>? removeRange(TextRange removalRange) {
    if (range.start >= removalRange.start &&
        (range.start < removalRange.end && range.end > removalRange.end)) {
      return [
        copy(
          range: TextRange(
            start: removalRange.end,
            end: range.end,
          ),
        ),
      ];
    } else if ((range.start < removalRange.start &&
            range.end > removalRange.start) &&
        range.end <= removalRange.end) {
      return [
        copy(
          range: TextRange(
            start: range.start,
            end: removalRange.start,
          ),
        ),
      ];
    } else if (range.start < removalRange.start &&
        range.end > removalRange.end) {
      return [
        copy(
          range: TextRange(
            start: range.start,
            end: removalRange.start,
          ),
          expand: removalRange.isCollapsed ? false : expand,
        ),
        copy(
          range: TextRange(
            start: removalRange.end,
            end: range.end,
          ),
        ),
      ];
    } else if (range.start >= removalRange.start &&
        range.end <= removalRange.end) {
      return null;
    } else if (range.start > removalRange.start &&
        range.start >= removalRange.end) {
      return [this];
    } else if (range.end <= removalRange.start &&
        range.end < removalRange.end) {
      return [this];
    } else if (removalRange.isCollapsed && range.end == removalRange.start) {
      return [this];
    }

    return null;
  }

  /// 创建一个新的Replacement
  TextEditingInlineSpanReplacement copy({TextRange? range, bool? expand}) {
    return TextEditingInlineSpanReplacement(
        range ?? this.range, generator, expand ?? this.expand);
  }

  @override
  String toString() {
    return 'TextEditingInlineSpanReplacement { range: $range, generator: $generator }';
  }
}

class ReplacementTextEditingController extends TextEditingController {
  List<TextEditingInlineSpanReplacement>? replacements;
  final bool composingRegionReplaceable;

  ReplacementTextEditingController({
    super.text,
    List<TextEditingInlineSpanReplacement>? replacements,
    this.composingRegionReplaceable = true,
  }) : replacements = replacements ?? [];

  void applyReplacement(TextEditingInlineSpanReplacement replacement) {
    if (replacements == null) {
      replacements = [];
      replacements!.add(replacement);
    } else {
      replacements!.add(replacement);
    }
  }

  void syncReplacementRanges(TextEditingDelta delta) {
    if (replacements == null) return;

    if (text.isEmpty) replacements!.clear();

    List<TextEditingInlineSpanReplacement> toRemove = [];
    List<TextEditingInlineSpanReplacement> toAdd = [];

    for (int i = 0; i < replacements!.length; i++) {
      late final TextEditingInlineSpanReplacement? mutatedReplacement;

      if (delta is TextEditingDeltaInsertion) {
        mutatedReplacement = replacements![i].onInsertion(delta);
      } else if (delta is TextEditingDeltaDeletion) {
        mutatedReplacement = replacements![i].onDelete(delta);
      } else if (delta is TextEditingDeltaReplacement) {
        List<TextEditingInlineSpanReplacement>? newReplacements;
        newReplacements = replacements![i].onReplacement(delta);

        if (newReplacements != null) {
          if (newReplacements.length == 1) {
            mutatedReplacement = newReplacements[0];
          } else {
            mutatedReplacement = null;
            toAdd.addAll(newReplacements);
          }
        } else {
          mutatedReplacement = null;
        }
      } else if (delta is TextEditingDeltaNonTextUpdate) {
        mutatedReplacement = replacements![i].onNonTextUpdate(delta);
      }

      if (mutatedReplacement == null) {
        toRemove.add(replacements![i]);
      } else {
        replacements![i] = mutatedReplacement;
      }
    }

    for (final TextEditingInlineSpanReplacement replacementToRemove
        in toRemove) {
      replacements!.remove(replacementToRemove);
    }

    replacements!.addAll(toAdd);
  }

  ///构建TextSpan
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    assert(!value.composing.isValid ||
        !withComposing ||
        value.isComposingRangeValid);

    //保留TextRanges到InlineSpan的映射以替换它。
    final Map<TextRange, InlineSpan> rangeSpanMapping =
        <TextRange, InlineSpan>{};

    // 迭代TextEditingInlineSpanReplacement，将它们映射到生成的InlineSpan。
    if (replacements != null) {
      for (final TextEditingInlineSpanReplacement replacement
          in replacements!) {
        _addToMappingWithOverlaps(
            replacement.generator,
            TextRange(
                start: replacement.range.start, end: replacement.range.end),
            rangeSpanMapping,
            value.text,
            isWidget: replacement.isWidget);
      }
    }

    if (composingRegionReplaceable &&
        value.isComposingRangeValid &&
        withComposing) {
      _addToMappingWithOverlaps((value, range) {
        final TextStyle composingStyle = style != null
            ? style.merge(const TextStyle(decoration: TextDecoration.underline))
            : const TextStyle(decoration: TextDecoration.underline);
        return TextSpan(
          style: composingStyle,
          text: value,
        );
      }, value.composing, rangeSpanMapping, value.text);
    }
    // 根据开始索引对匹配进行排序
    final List<TextRange> sortedRanges = rangeSpanMapping.keys.toList();
    sortedRanges.sort((a, b) => a.start.compareTo(b.start));

    // 为未替换的文本范围创建TextSpan并插入替换的span
    final List<InlineSpan> spans = <InlineSpan>[];
    int previousEndIndex = 0;

    for (final TextRange range in sortedRanges) {
      if (range.start > previousEndIndex) {
        spans.add(TextSpan(
            text: value.text.substring(previousEndIndex, range.start)));
      }
      spans.add(rangeSpanMapping[range]!);
      previousEndIndex = range.end;
    }
    // 后面添加的文字使用默认的TextSpan
    if (previousEndIndex < value.text.length) {
      spans.add(TextSpan(
          text: value.text.substring(previousEndIndex, value.text.length)));
    }
    return TextSpan(
      style: style,
      children: spans,
    );
  }

  static void _addToMappingWithOverlaps(
      InlineSpanGenerator generator,
      TextRange matchedRange,
      Map<TextRange, InlineSpan> rangeSpanMapping,
      String text,
      {bool? isWidget}) {
    // 在某些情况下，应该允许重叠。
    // 例如在两个TextSpan匹配相同的替换范围的情况下，
    // 尝试合并到一个TextStyle的风格，并建立一个新的TextSpan。
    bool overlap = false;
    List<TextRange> overlapRanges = <TextRange>[];
    //遍历索引
    for (final TextRange range in rangeSpanMapping.keys) {
      if (math.max(matchedRange.start, range.start) <=
          math.min(matchedRange.end, range.end)) {
        overlap = true;
        overlapRanges.add(range);
      }
    }

    final List<List<dynamic>> overlappingTriples = <List<dynamic>>[];

    if (overlap) {
      overlappingTriples.add(<dynamic>[
        matchedRange.start,
        matchedRange.end,
        generator(matchedRange.textInside(text), matchedRange).style
      ]);

      for (final TextRange overlappingRange in overlapRanges) {
        overlappingTriples.add(<dynamic>[
          overlappingRange.start,
          overlappingRange.end,
          rangeSpanMapping[overlappingRange]!.style
        ]);
        rangeSpanMapping.remove(overlappingRange);
      }

      final List<dynamic> toRemoveRangesThatHaveBeenMerged = <dynamic>[];
      final List<dynamic> toAddRangesThatHaveBeenMerged = <dynamic>[];
      for (int i = 0; i < overlappingTriples.length; i++) {
        bool didOverlap = false;
        List<dynamic> tripleA = overlappingTriples[i];
        if (toRemoveRangesThatHaveBeenMerged.contains(tripleA)) continue;
        for (int j = i + 1; j < overlappingTriples.length; j++) {
          final List<dynamic> tripleB = overlappingTriples[j];
          if (math.max(tripleA[0] as int, tripleB[0] as int) <=
                  math.min(tripleA[1] as int, tripleB[1] as int) &&
              tripleA[2] == tripleB[2]) {
            toRemoveRangesThatHaveBeenMerged
                .addAll(<dynamic>[tripleA, tripleB]);
            tripleA = <dynamic>[
              math.min(tripleA[0] as int, tripleB[0] as int),
              math.max(tripleA[1] as int, tripleB[1] as int),
              tripleA[2],
            ];
            didOverlap = true;
          }
        }

        if (didOverlap &&
            !toAddRangesThatHaveBeenMerged.contains(tripleA) &&
            !toRemoveRangesThatHaveBeenMerged.contains(tripleA)) {
          toAddRangesThatHaveBeenMerged.add(tripleA);
        }
      }

      for (var tripleToRemove in toRemoveRangesThatHaveBeenMerged) {
        overlappingTriples.remove(tripleToRemove);
      }

      for (var tripleToAdd in toAddRangesThatHaveBeenMerged) {
        overlappingTriples.add(tripleToAdd as List<dynamic>);
      }

      List<int> endPoints = <int>[];
      for (List<dynamic> triple in overlappingTriples) {
        Set<int> ends = <int>{};
        ends.add(triple[0] as int);
        ends.add(triple[1] as int);
        endPoints.addAll(ends.toList());
      }
      endPoints.sort();
      if (isWidget == true) {
      } else {
        Map<int, Set<TextStyle>> start = <int, Set<TextStyle>>{};
        Map<int, Set<TextStyle>> end = <int, Set<TextStyle>>{};

        for (final int e in endPoints) {
          start[e] = <TextStyle>{};
          end[e] = <TextStyle>{};
        }

        for (List<dynamic> triple in overlappingTriples) {
          start[triple[0]]!.add(triple[2] as TextStyle);
          end[triple[1]]!.add(triple[2] as TextStyle);
        }

        Set<TextStyle> styles = <TextStyle>{};
        List<int> otherEndPoints =
            endPoints.getRange(1, endPoints.length).toList();
        for (int i = 0; i < endPoints.length - 1; i++) {
          styles = styles.difference(end[endPoints[i]]!);
          styles.addAll(start[endPoints[i]]!);
          TextStyle? mergedStyles;
          final TextRange uniqueRange =
              TextRange(start: endPoints[i], end: otherEndPoints[i]);
          for (final TextStyle style in styles) {
            if (mergedStyles == null) {
              mergedStyles = style;
            } else {
              mergedStyles = mergedStyles.merge(style);
            }
          }
          rangeSpanMapping[uniqueRange] =
              TextSpan(text: uniqueRange.textInside(text), style: mergedStyles);
        }
      }
    }

    if (!overlap) {
      rangeSpanMapping[matchedRange] =
          generator(matchedRange.textInside(text), matchedRange);
    }

    // 清理不需要样式的范围
    final List<TextRange> toRemove = <TextRange>[];

    for (final TextRange range in rangeSpanMapping.keys) {
      if (range.isCollapsed) toRemove.add(range);
    }

    for (final TextRange range in toRemove) {
      rangeSpanMapping.remove(range);
    }
  }

  void disableExpand(TextStyle style) {
    final List<TextEditingInlineSpanReplacement> toRemove = [];
    final List<TextEditingInlineSpanReplacement> toAdd = [];

    for (final TextEditingInlineSpanReplacement replacement in replacements!) {
      if (replacement.range.end == selection.start) {
        TextStyle? replacementStyle = (replacement.generator(
                '', const TextRange.collapsed(0)) as TextSpan)
            .style;
        if (replacementStyle! == style) {
          toRemove.add(replacement);
          toAdd.add(replacement.copy(expand: false));
        }
      }
    }

    for (final TextEditingInlineSpanReplacement replacementToRemove
        in toRemove) {
      replacements!.remove(replacementToRemove);
    }

    for (final TextEditingInlineSpanReplacement replacementWithExpandDisabled
        in toAdd) {
      replacements!.add(replacementWithExpandDisabled);
    }
  }

  List<TextStyle> getReplacementsAtSelection(TextSelection selection) {
    // 只有[left replacement]才会被reported
    final List<TextStyle> stylesAtSelection = <TextStyle>[];

    for (final TextEditingInlineSpanReplacement replacement in replacements!) {
      if (replacement.isWidget == true) {

      } else {
        if (selection.isCollapsed) {
          if (math.max(replacement.range.start, selection.start) <=
              math.min(replacement.range.end, selection.end)) {
            if (selection.end != replacement.range.start) {
              if (selection.start == replacement.range.end) {
                if (replacement.expand) {
                  stylesAtSelection
                      .add(replacement.generator('', replacement.range).style!);
                }
              } else {
                stylesAtSelection
                    .add(replacement.generator('', replacement.range).style!);
              }
            }
          }
        } else {
          if (math.max(replacement.range.start, selection.start) <=
              math.min(replacement.range.end, selection.end)) {
            if (replacement.range.start <= selection.start &&
                replacement.range.end >= selection.end) {
              stylesAtSelection
                  .add(replacement.generator('', replacement.range).style!);
            }
          }
        }
      }
    }

    return stylesAtSelection;
  }

  void removeReplacementsAtRange(TextRange removalRange, TextStyle? attribute) {
    final List<TextEditingInlineSpanReplacement> toRemove = [];
    final List<TextEditingInlineSpanReplacement> toAdd = [];

    for (int i = 0; i < replacements!.length; i++) {
      TextEditingInlineSpanReplacement replacement = replacements![i];
      InlineSpan replacementSpan =
          replacement.generator('', const TextRange.collapsed(0));
      TextStyle? replacementStyle = replacementSpan.style;
      late final TextEditingInlineSpanReplacement? mutatedReplacement;

      if ((math.max(replacement.range.start, removalRange.start) <=
              math.min(replacement.range.end, removalRange.end)) &&
          replacementStyle != null) {
        if (replacementStyle == attribute!) {
          List<TextEditingInlineSpanReplacement>? newReplacements =
              replacement.removeRange(removalRange);

          if (newReplacements != null) {
            if (newReplacements.length == 1) {
              mutatedReplacement = newReplacements[0];
            } else {
              mutatedReplacement = null;
              toAdd.addAll(newReplacements);
            }
          } else {
            mutatedReplacement = null;
          }

          if (mutatedReplacement == null) {
            toRemove.add(replacements![i]);
          } else {
            replacements![i] = mutatedReplacement;
          }
        }
      }
    }

    for (TextEditingInlineSpanReplacement replacementToAdd in toAdd) {
      replacements!.add(replacementToAdd);
    }

    for (TextEditingInlineSpanReplacement replacementToRemove in toRemove) {
      replacements!.remove(replacementToRemove);
    }
  }
}
