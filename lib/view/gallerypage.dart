import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mangw/style.dart';
import 'package:mangw/view/gallerycard.dart';

class GalleryPageController extends ChangeNotifier {
  GlobalKey? _item;
  int _crossAxisCount = 0;
  double _spacing = 0;
  ScrollController? _scrollController;
  int _highlightIndex = 0;

  int get highlightPosition => _highlightIndex;

  int getCrossAxisCount() {
    return _crossAxisCount;
  }

  bool scrollTo(int index) {
    try {
      var context = _item!.currentContext!;
      double offset = ((index ~/ _crossAxisCount)).floor() *
          (context.size!.height + _spacing);
      _scrollController?.animateTo(offset,
          duration: const Duration(seconds: 1), curve: Curves.decelerate);
      return true;
    } catch (e) {
      return false;
    }
  }

  void highlightItem(int index) {
    _highlightIndex = index;
    notifyListeners();
  }

  ScrollController setScroller(ScrollController scroller) {
    return _scrollController = scroller;
  }

  void setFactor(GlobalKey activeItemKey, int crossAxisCount, double spacing) {
    _item = activeItemKey;
    _crossAxisCount = crossAxisCount;
    _spacing = spacing;
  }
}

abstract class GalleryPageAdapter<T> {
  T getItem(int index);
  String getItemImage(int index);
  int getSize();
  void onItemTap(T item) {}
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.adapter, this.controller});

  final GalleryPageAdapter adapter;
  final GalleryPageController? controller;

  @override
  State<StatefulWidget> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> with WidgetsBindingObserver {
  late Size _lastSize;
  final double _spacing = 25.0;

  int get _crossAxisCount => _lastSize.width > 1440
      ? 8
      : _lastSize.width > 960
          ? 6
          : _lastSize.width > 640
              ? 4
              : _lastSize.width > 480
                  ? 2
                  : 1;

  final ScrollController _scroller = ScrollController();

  Size _calcDisplaySize() {
    return WidgetsBinding.instance.window.physicalSize /
        WidgetsBinding.instance.window.devicePixelRatio;
  }

  @override
  void didChangeMetrics() {
    setState(() {
      _lastSize = _calcDisplaySize();
    });
  }

  @override
  void initState() {
    super.initState();
    _lastSize = _calcDisplaySize();
    widget.controller?.setScroller(_scroller);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // hack controller highlight position when remove item. need better solution.
    int lastIndex = widget.adapter.getSize() - 1;
    if (widget.controller != null &&
        widget.controller!._highlightIndex > lastIndex) {
      widget.controller!._highlightIndex = lastIndex;
    }

    return Container(
      color: mcgpalette0Accent,
      child: AlignedGridView.count(
          controller: _scroller,
          padding: EdgeInsets.all(_spacing),
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          crossAxisCount: _crossAxisCount,
          itemCount: widget.adapter.getSize(),
          itemBuilder: (BuildContext itemBuilderContext, int index) {
            return AnimatedBuilder(
                animation: widget.controller ?? GalleryPageController(),
                builder: (context, child) {
                  GlobalObjectKey? activeItemKey;
                  bool isSelected =
                      widget.controller?.highlightPosition == index;
                  if (isSelected) {
                    activeItemKey =
                        GlobalObjectKey(widget.adapter.getItem(index));
                    widget.controller?.setFactor(
                      activeItemKey,
                      _crossAxisCount,
                      _spacing,
                    );
                  }
                  return GalleryCard(
                    key: activeItemKey,
                    image: widget.adapter.getItemImage(index),
                    isSelected: isSelected,
                    onPress: (data) {
                      widget.adapter.onItemTap
                          .call(widget.adapter.getItem(index));
                      widget.controller?.highlightItem(index);
                    },
                    onLongPress: (data) {
                      widget.adapter.onItemTap
                          .call(widget.adapter.getItem(index));
                      widget.controller?.highlightItem(index);
                    },
                  );
                });
          }),
    );
  }
}
