// ignore_for_file: avoid_unnecessary_containers

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'indicator.dart';

typedef IndexItemBuilder<T> = Widget Function(
  BuildContext context,
  int index,
  T item,
  bool isSelected,
)?;

typedef IndexIndicatorBuilder<T> = Widget Function(
    BuildContext context, int? index, T? selectedItem);

typedef OnSelectedItemChanged<T> = void Function(T item, int index)?;

class IndexBar<T> extends StatefulWidget {
  IndexBar({
    Key? key,
    this.backgroundColor = Colors.black12,
    required this.items,
    required this.itemBuilder,
    this.width = 30,
    this.padding = const EdgeInsets.only(top: 15, bottom: 15),
    this.margin = const EdgeInsets.only(right: 10),
    this.onSelectedItemChanged,
    this.indicatorWidth = 60,
    this.indicatorHeight = 50,
    this.indicatorRadius = 8,
    this.indicatorMarginRight = 0,
    this.indicatorColor = Colors.black87,
    this.indicatorArrowWidth = 10,
    this.indicatorArrowHeight = 10,
    this.indicatorBuilder,
    this.defaultIndicatorBuilder,
  }) : super(key: key);

  final Color backgroundColor;
  final double width;
  final EdgeInsets padding;
  final EdgeInsets margin;

  /// 索引条默认的指示器构造器，构造的 widget 会包含在带箭头的圆角矩形中。
  final IndexIndicatorBuilder<T>? defaultIndicatorBuilder;
  final double indicatorArrowHeight;
  final double indicatorArrowWidth;

  /// 索引条指示器构造器，构造的 widget 由调用者完全控制
  final IndexIndicatorBuilder<T>? indicatorBuilder;
  final Color indicatorColor;
  final double indicatorHeight;
  final double indicatorMarginRight;
  final double indicatorRadius;
  final double indicatorWidth;
  // assert(indicatorBuilder == null && defaultIndicatorBuilder == null,
  // 'indicatorBuilder and defaultIndicatorBuilder cannot be null at the same time'),

  /// 索引条每条索引构造器
  final IndexItemBuilder<T> itemBuilder;

  final List<T> items;
  final OnSelectedItemChanged<T>? onSelectedItemChanged;

  late final Map<T, UniqueGlobalObjectKey> _itemKeyPairs = {};
  late final UniqueGlobalObjectKey<IndexBarState<T>> _itemsContainerKey =
      UniqueGlobalObjectKey(debugLabel: 'itemsContainerKey');

  @override
  IndexBarState createState() => IndexBarState<T>();
}

class IndexBarState<T> extends State<IndexBar<T>> {
  StreamController<double?>? _indicatorYController;
  Stream<double?>? _indicatorYStream;
  StreamSubscription<double?>? _indicatorYSubscription;
  int? _selectedIndex;
  StreamController<int>? _selectedIndexController;
  Stream<int>? _selectedIndexStream;
  StreamSubscription<int>? _selectedIndexSubscription;

  @override
  void dispose() {
    super.dispose();
    _indicatorYSubscription?.cancel();
    _indicatorYController?.close();
    _selectedIndexSubscription?.cancel();
    _selectedIndexController?.close();
  }

  @override
  void initState() {
    print('$this initState ...');
    super.initState();
    _indicatorYController = StreamController<double?>();
    _selectedIndexController = StreamController<int>();
    _selectedIndexStream = _selectedIndexController!.stream
        // .transform(throttle(const Duration(milliseconds: 100)))
        .asBroadcastStream();
    _selectedIndexSubscription = _selectedIndexStream?.listen((index) {
      print('$this current selected item index is $index');
      widget.onSelectedItemChanged!(widget.items[index], index);
    });
    _indicatorYStream = _indicatorYController!.stream.asBroadcastStream();
    _indicatorYSubscription = _indicatorYStream?.listen((event) {
      print('$this current indicator y is $event');
    });
  }

  StreamTransformer<K, K> throttle<K>(Duration duration) {
    Timer? timer;
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (timer == null) {
          sink.add(data);
          timer = Timer(duration, () {
            timer = null;
          });
        }
      },
      handleError: (error, stackTrace, sink) =>
          sink.addError(error, stackTrace),
      handleDone: (sink) {
        sink.close();
        timer?.cancel();
      },
    );
  }

  List<T> get _items => widget.items;

  T? get _selectedItem =>
      _selectedIndex == null ? null : widget.items[_selectedIndex!];

  void _selectItemAtIndex(
    BuildContext context,
    int index, {
    bool updatePosition = true,
  }) {
    print('追加 ---- 选择的 index 为 $index ');
    _selectedIndexController?.add(index);
    // if (_selectedIndex == index) {
    //   return;
    // }
    _selectedIndex = index;
    final item = _items[index];
    final itemKey = widget._itemKeyPairs[item]!;
    final ancestor = widget._itemsContainerKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (ancestor == null) {
      return;
    }
    final itemBox = itemKey.currentContext!.findRenderObject() as RenderBox;
    final position = itemBox.localToGlobal(
      Offset.zero,
      ancestor: ancestor,
    );
    final size = itemBox.size;
    _indicatorYController?.add(position.dy + size.height / 2);
    if (updatePosition && widget.onSelectedItemChanged != null) {
      // widget.onSelectedItemChanged!(item, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      // color: Colors.teal,
      child: SizedBox(
        width: widget.margin.left +
            widget.margin.right +
            widget.width +
            widget.indicatorWidth +
            widget.indicatorMarginRight,
        child: Stack(
          alignment: Alignment.centerRight,
          key: widget._itemsContainerKey,
          children: [
            // Positioned(child: IconButton(onPressed: onPressed, icon: icon))
            StreamBuilder(
              builder: (context, snapshot) {
                final top = snapshot.data == null
                    ? 0.0
                    : snapshot.data! - widget.indicatorHeight / 2;
                print('indicator Y should be $top');
                return Positioned(
                  left: 0,
                  top: top,
                  child: Visibility(
                    visible: snapshot.data != null,
                    child: widget.indicatorBuilder != null
                        ? Container(
                            alignment: Alignment.center,
                            width: widget.indicatorArrowWidth,
                            height: widget.indicatorHeight,
                            child: widget.indicatorBuilder!(
                              context,
                              _selectedIndex,
                              _selectedItem,
                            ),
                          )
                        : RoundedRectangleWithArrow(
                            width: widget.indicatorWidth,
                            height: widget.indicatorHeight,
                            borderRadius: widget.indicatorRadius,
                            arrowPosition: ArrowPosition.right,
                            color: widget.indicatorColor,
                            arrowWidth: widget.indicatorArrowWidth,
                            arrowHeight: widget.indicatorArrowHeight,
                            child: Center(
                              child: widget.defaultIndicatorBuilder!(
                                context,
                                _selectedIndex,
                                _selectedItem,
                              ),
                            ),
                          ),
                  ),
                );
              },
              stream: _indicatorYStream,
              initialData: null,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent, // 透明区域也响应事件
              onVerticalDragUpdate: (details) {
                // = context.findRenderObject() as RenderBox;
                final ancestor = widget._itemsContainerKey.currentContext!
                    .findRenderObject() as RenderBox;
                final localPosition =
                    ancestor.globalToLocal(details.globalPosition);

                if (localPosition.dx < 0 ||
                    localPosition.dx > ancestor.size.width ||
                    localPosition.dy > ancestor.size.height ||
                    localPosition.dy < 0) {
                  return;
                }
                // print(
                //     '手指位置 $localPosition ${ancestor.size} ${details.localPosition}');
                widget.items.forEachIndexed((index, item) {
                  final itemKey = widget._itemKeyPairs[item]!;
                  final itemBox =
                      itemKey.currentContext?.findRenderObject() as RenderBox?;
                  final position =
                      itemBox?.localToGlobal(Offset.zero, ancestor: ancestor);
                  final size = itemBox?.size;
                  // print('itemBox $item $position $size');
                  if (_selectedIndex != index &&
                      localPosition.dy >= position!.dy &&
                      localPosition.dy <= position.dy + size!.height) {
                    _selectItemAtIndex(context, index);
                    return;
                  }
                });
              },
              onVerticalDragEnd: (details) {
                _indicatorYController?.add(null);
              },
              child: Padding(
                padding: widget.margin,
                child: Container(
                  width: widget.width,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(widget.width / 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: widget.items.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final itemKey = widget._itemKeyPairs[item] ??=
                            UniqueGlobalObjectKey(debugLabel: '$item');
                        print('为 item $item 设置 key 为 $itemKey ');
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _selectItemAtIndex(context, index),
                          child: KeyedSubtree(
                            key: itemKey,
                            child: StreamBuilder(
                              builder: (context, snapshot) {
                                bool isSelected = snapshot.data == index;
                                return widget.itemBuilder!(
                                  context,
                                  index,
                                  item,
                                  isSelected,
                                );
                              },
                              stream: _selectedIndexStream,
                              initialData: 0,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThrottleFilter<T> {
  ThrottleFilter(this.duration);

  final Duration duration;
  DateTime? lastEventDateTime;

  bool call(T e) {
    final now = DateTime.now();
    if (lastEventDateTime == null ||
        now.difference(lastEventDateTime!) > duration) {
      lastEventDateTime = now;
      return true;
    }
    return false;
  }
}

class UniqueObject {
  UniqueObject({required this.label});
  final String? label;
  @override
  String toString() {
    return "${identityHashCode(this)} $label";
  }
}

class UniqueGlobalObjectKey<T extends State<StatefulWidget>>
    extends GlobalObjectKey<T> {
  UniqueGlobalObjectKey({this.debugLabel})
      : super(UniqueObject(label: debugLabel));
  final String? debugLabel;

  @override
  String toString() {
    if (kDebugMode) {
      return 'UniqueGlobalObjectKey ${identityHashCode(this)}: debugLabel: $debugLabel';
    }
    return super.toString();
  }
}
