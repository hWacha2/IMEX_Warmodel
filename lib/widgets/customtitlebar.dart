import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/rendering.dart';

/// A drop-in replacement for [TitleBar] that supports window dragging
/// and double-tap maximization, but does NOT intercept pointer events
/// on interactive child widgets (buttons, toggles, etc.).
///
/// Gestures are applied only to empty regions, not to the entire bar.
class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({
    super.key,
    this.isBackButtonEnabled,
    this.isBackButtonVisible = true,
    this.backButton,
    this.onBackRequested,
    this.leftHeader,
    this.icon,
    this.title,
    this.subtitle,
    this.content,
    this.endHeader,
    this.height,
    this.captionControls,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragCancelled,
    this.onDragUpdated,
    this.onDoubleTap,
  });

  final bool? isBackButtonEnabled;
  final bool isBackButtonVisible;
  final Widget? backButton;
  final VoidCallback? onBackRequested;
  final Widget? leftHeader;
  final Widget? icon;
  final Widget? title;
  final Widget? subtitle;
  final Widget? content;
  final Widget? endHeader;
  final double? height;
  final Widget? captionControls;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final VoidCallback? onDragCancelled;
  final VoidCallback? onDragUpdated;
  final VoidCallback? onDoubleTap;

  static double calculateHeight(Widget? titleBar) {
    if (titleBar == null) return 0;
    if (titleBar is CustomTitleBar) {
      if (titleBar.height != null) return titleBar.height!;
      if (titleBar.content != null) return 48;
    }
    return 32;
  }

  /// Wraps a widget with drag/double-tap gestures only if callbacks are provided.
  Widget _maybeDraggable({required Widget child}) {
    if (onDragStarted == null && onDoubleTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => onDragStarted?.call(),
      onPanEnd: (_) => onDragEnded?.call(),
      onPanCancel: () => onDragCancelled?.call(),
      onPanUpdate: (_) => onDragUpdated?.call(),
      onDoubleTap: () => onDoubleTap?.call(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (innerContext) {
      assert(debugCheckHasFluentTheme(context));
      final theme = FluentTheme.of(context);
      final view = NavigationView.dataOf(context);

      final isPaneToggleButtonVisible =
          view.toggleButtonPosition == PaneToggleButtonPosition.titleBar;

      final calculatedHeight = CustomTitleBar.calculateHeight(this);

      return ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: calculatedHeight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === LEFT SECTION ===
            Expanded(
              flex: 2,
              child: _maybeDraggable(
                child: Row(
                  children: [
                    if (isBackButtonVisible)
                      backButton ??
                          PaneBackButton(
                            onPressed: onBackRequested,
                            enabled: isBackButtonEnabled ?? true,
                          ),
                    // Кнопка переключения панели — НЕ оборачивается в GestureDetector
                    if (isPaneToggleButtonVisible &&
                        view.pane?.toggleButton != null)
                      view.pane!.toggleButton!,

                    if (leftHeader != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 16),
                        child: leftHeader,
                      ),
                    if (icon != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 16),
                        child: icon,
                      ),
                    if (title != null || subtitle != null)
                      Flexible(
                        child: _TitleSubtitleOverflow(
                          title: title != null
                              ? DefaultTextStyle.merge(
                                  style: theme.typography.body?.copyWith(
                                    color: theme.resources.textFillColorPrimary,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  child: title!,
                                )
                              : null,
                          subtitle: subtitle != null
                              ? DefaultTextStyle.merge(
                                  style: theme.typography.body?.copyWith(
                                    color:
                                        theme.resources.textFillColorSecondary,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  child: subtitle!,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // === CENTER CONTENT ===
            if (content != null) Expanded(child: content!),

            // === RIGHT SECTION ===
            Expanded(
              flex: 2,
              child: _maybeDraggable(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (endHeader != null) endHeader!,
                    // Минимальная область для перетаскивания справа
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48),
                    ),
                    if (captionControls != null)
                      Flexible(child: captionControls!),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ============================================================================
// Вспомогательный виджет для обработки переполнения заголовка/подзаголовка
// ============================================================================

class _TitleSubtitleOverflow extends MultiChildRenderObjectWidget {
  const _TitleSubtitleOverflow({required this.title, required this.subtitle});

  final Widget? title;
  final Widget? subtitle;

  @override
  List<Widget> get children {
    final result = <Widget>[];
    if (title != null) {
      result.add(
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
          child: title!,
        ),
      );
    }
    if (subtitle != null) {
      result.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: subtitle!,
        ),
      );
    }
    return result;
  }

  @override
  _RenderTitleSubtitleOverflow createRenderObject(BuildContext context) {
    return _RenderTitleSubtitleOverflow(
      hasTitle: title != null,
      hasSubtitle: subtitle != null,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTitleSubtitleOverflow renderObject,
  ) {
    renderObject
      ..hasTitle = title != null
      ..hasSubtitle = subtitle != null;
  }
}

class _TitleSubtitleOverflowParentData
    extends ContainerBoxParentData<RenderBox> {
  bool isHidden = false;
}

class _RenderTitleSubtitleOverflow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TitleSubtitleOverflowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            _TitleSubtitleOverflowParentData> {
  _RenderTitleSubtitleOverflow({
    required bool hasTitle,
    required bool hasSubtitle,
  })  : _hasTitle = hasTitle,
        _hasSubtitle = hasSubtitle;

  bool _hasTitle;
  bool get hasTitle => _hasTitle;
  set hasTitle(bool value) {
    if (_hasTitle != value) {
      _hasTitle = value;
      markNeedsLayout();
    }
  }

  bool _hasSubtitle;
  bool get hasSubtitle => _hasSubtitle;
  set hasSubtitle(bool value) {
    if (_hasSubtitle != value) {
      _hasSubtitle = value;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TitleSubtitleOverflowParentData) {
      child.parentData = _TitleSubtitleOverflowParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var width = 0.0;
    var child = firstChild;
    while (child != null) {
      width += child.getMinIntrinsicWidth(height);
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var width = 0.0;
    var child = firstChild;
    while (child != null) {
      width += child.getMaxIntrinsicWidth(height);
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      height = height > child.getMinIntrinsicHeight(width)
          ? height
          : child.getMinIntrinsicHeight(width);
      child = childAfter(child);
    }
    return height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      height = height > child.getMaxIntrinsicHeight(width)
          ? height
          : child.getMaxIntrinsicHeight(width);
      child = childAfter(child);
    }
    return height;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _performLayout(constraints, dry: true);
  }

  Size _performLayout(BoxConstraints constraints, {required bool dry}) {
    if (firstChild == null) return constraints.smallest;

    RenderBox? titleChild;
    RenderBox? subtitleChild;
    var child = firstChild;
    var index = 0;
    while (child != null) {
      if (index == 0 && hasTitle) {
        titleChild = child;
      } else if ((index == 0 && !hasTitle && hasSubtitle) ||
          (index == 1 && hasTitle && hasSubtitle)) {
        subtitleChild = child;
      }
      child = childAfter(child);
      index++;
    }

    var titleWidth = 0.0;
    var subtitleWidth = 0.0;
    var maxHeight = 0.0;

    if (titleChild != null) {
      final titleConstraints = BoxConstraints(maxHeight: constraints.maxHeight);
      final titleSize = titleChild.getDryLayout(titleConstraints);
      titleWidth = titleSize.width;
      maxHeight = maxHeight > titleSize.height ? maxHeight : titleSize.height;
    }

    if (subtitleChild != null) {
      final subtitleConstraints =
          BoxConstraints(maxHeight: constraints.maxHeight);
      final subtitleSize = subtitleChild.getDryLayout(subtitleConstraints);
      subtitleWidth = subtitleSize.width;
      maxHeight =
          maxHeight > subtitleSize.height ? maxHeight : subtitleSize.height;
    }

    final totalWidth = titleWidth + subtitleWidth;
    final availableWidth = constraints.maxWidth;

    var showTitle = true;
    var showSubtitle = true;

    if (availableWidth.isFinite) {
      if (totalWidth > availableWidth) {
        showSubtitle = false;
        if (titleWidth > availableWidth) showTitle = false;
      } else if (hasTitle && !hasSubtitle && titleWidth > availableWidth) {
        showTitle = false;
      }
    }

    if (!dry) {
      child = firstChild;
      index = 0;
      while (child != null) {
        final childParentData =
            child.parentData! as _TitleSubtitleOverflowParentData;
        if (index == 0 && hasTitle) {
          childParentData.isHidden = !showTitle;
        } else if ((index == 0 && !hasTitle && hasSubtitle) ||
            (index == 1 && hasTitle && hasSubtitle)) {
          childParentData.isHidden = !showSubtitle;
        } else {
          childParentData.isHidden = false;
        }
        child = childAfter(child);
        index++;
      }
    }

    final finalWidth = showTitle && showSubtitle
        ? totalWidth
        : showTitle
            ? titleWidth
            : 0.0;

    return Size(
      constraints.constrainWidth(finalWidth),
      constraints.constrainHeight(maxHeight),
    );
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    size = _performLayout(constraints, dry: false);

    var child = firstChild;
    while (child != null) {
      final childParentData =
          child.parentData! as _TitleSubtitleOverflowParentData;
      if (!childParentData.isHidden) {
        final childConstraints = BoxConstraints.loose(size);
        child.layout(childConstraints, parentUsesSize: true);
        childParentData.offset = Offset.zero;
      }
      child = childAfter(child);
    }

    var offset = 0.0;
    child = firstChild;
    while (child != null) {
      final childParentData =
          child.parentData! as _TitleSubtitleOverflowParentData;
      if (!childParentData.isHidden) {
        childParentData.offset = Offset(offset, 0);
        offset += child.size.width;
      }
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = firstChild;
    while (child != null) {
      final childParentData =
          child.parentData! as _TitleSubtitleOverflowParentData;
      if (!childParentData.isHidden) {
        final isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (result, transformed) {
            assert(transformed == position - childParentData.offset);
            return child!.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
      child = childAfter(child);
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final childParentData =
          child.parentData! as _TitleSubtitleOverflowParentData;
      if (!childParentData.isHidden) {
        context.paintChild(child, offset + childParentData.offset);
      }
      child = childAfter(child);
    }
  }
}
