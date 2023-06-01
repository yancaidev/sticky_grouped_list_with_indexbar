// 基于 [scrollable_positioned_list] 实现分组和分组吸顶效果
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'index_bar.dart';

typedef StickyGroupListItemBuilder<E> = Widget Function(
  BuildContext context,
  E item,
);

typedef StickyGroupListHeaderBuilder<S> = Widget Function(
  BuildContext context,
  S item,
);

/// 该组件包含以下功能，列表分组，分组吸顶，分组快速索引
/// - [S] 表示分组，是 Section 的缩写
/// - [E] 表示分组中的元素，是 Element 的缩写
class StickyPositionedGroupList<S, E> extends StatefulWidget {
  const StickyPositionedGroupList(
      {super.key,
      required this.dataSource,
      required this.itemBuilder,
      required this.headerBuilder,
      this.separatorBuilder,
      this.itemScrollController, 
      this.onHeaderChanged});

  /// 数据源
  final DataSource<S, E> dataSource;

  // 分割线构造器
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// 分组头部构造器
  final StickyGroupListHeaderBuilder<S> headerBuilder;

  /// 分组头下每一行的构造器
  final StickyGroupListItemBuilder<E> itemBuilder;

  /// ScrollablePositionedList 滚动到指定 item 的控制器
  final ItemScrollController? itemScrollController;

  final void Function(S section)? onHeaderChanged;

  @override
  State<StickyPositionedGroupList<S, E>> createState() =>
      _StickyPositionedGroupListState<S, E>();
}

class _StickyPositionedGroupListState<S, E>
    extends State<StickyPositionedGroupList<S, E>> {
  /// ScrollablePositionedList 的 key
  late final GlobalKey _groupListKey = GlobalKey(debugLabel: 'group-list-key');

  /// ScrollablePositionedList 可见 items 的位置监听器
  late final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  /// 分组视图的 key
  late final Map<S, GlobalKey> _sectionHeaderKeys = {};

  /// 吸顶视图的 key
  late final GlobalKey _stickyHeaderKey =
      GlobalKey(debugLabel: 'sticky-header-key');

  /// 吸顶的分组的 Y 轴偏移量
  late final _stickyHeaderYStream = _stickyHeaderYStreamController.stream
      .distinct((i1, i2) => i1 == i2)
      .asBroadcastStream();

  /// 吸顶的分组的 Y 轴偏移量
  late final _stickyHeaderYStreamController = StreamController<double>();

  /// 当前吸顶的分组的数据模型
  late ItemWrapper _stickyItem = dataSource.wrappedSectionItems.first;

  /// 吸顶的分组的数据模型
  late final _stickyItemStream = _stickyItemStreamController.stream
      .distinct((i1, i2) => i1.rawSection == i2.rawSection)
      .asBroadcastStream();

  /// 吸顶视图的数据模型
  final _stickyItemStreamController = StreamController<ItemWrapper>();

  StreamSubscription<ItemWrapper>? _stickyItemSubscription;

  @override
  void dispose() {
    super.dispose();
    _stickyHeaderYStreamController.close();
    _stickyItemSubscription?.cancel();
    _stickyItemStreamController.close();
    _itemPositionsListener.itemPositions.removeListener(_listenItemPositions);
  }

  /// 监听可见 items 的位置，计算当前吸顶的组件
  void _listenItemPositions() {
    // NOTE: 通过 scrollTo 滚动到指定位置时，不要做下面的计算。滚动时，更新UI，会出现异常问题。
    // print(
    //     '$this all visible positions ${_itemPositionsListener.itemPositions.value}');

    // 获取当前吸顶的分组。
    final currentStickyHeaderPosition =
        _itemPositionsListener.itemPositions.value.reduce((pos, current) =>
            current.itemTrailingEdge < pos.itemTrailingEdge ? current : pos);
    // print('$this currentStickyHeaderPosition: $currentStickyHeaderPosition');

    final currentStickyItem =
        dataSource.findWrappedSectionItem(currentStickyHeaderPosition.index);
    _stickyItemStreamController.add(currentStickyItem);

    // 筛选出所有可见分组头的位置
    final visibleHeaderPositions = _itemPositionsListener.itemPositions.value
        .where((element) =>
            dataSource.wrappedItemAtIndex(element.index).isSection);
    ItemPosition? nextStickyHeaderPosition;
    // 剔除当前已经在显示的分组头的位置
    final otherHeaderPositions = visibleHeaderPositions.isNotEmpty
        ? visibleHeaderPositions.where((element) =>
            dataSource.wrappedItemAtIndex(element.index) != _stickyItem)
        : <ItemPosition>[];

    /// 如果有多个分组头可见，那么下一个吸顶的分组头就是可见分组头中 itemTrailingEdge 最小的那个。
    if (otherHeaderPositions.length > 1) {
      nextStickyHeaderPosition = otherHeaderPositions.reduce((pos, current) =>
          current.itemTrailingEdge < pos.itemTrailingEdge ? current : pos);
    }
    // print('${visibleHeaderPositions.map((e) => {
    //       "index": e.index,
    //       "leading": e.itemLeadingEdge,
    //       "key": dataSource.itemAtIndex(e.index).headerItem
    //     })}');
    // print('${visibleHeaderPositions.map((e) => {
    //       "index": e.index,
    //       "leading": e.itemLeadingEdge,
    //       "key": dataSource.itemAtIndex(e.index).headerItem
    //     })}');
    // print(
    //     '${currentStickyHeaderPosition.index} ${currentStickyItem.item} ${currentStickyHeaderPosition.itemLeadingEdge} ${currentStickyHeaderPosition.itemTrailingEdge}');

    if (nextStickyHeaderPosition != null) {
      final nextItem =
          dataSource.wrappedItemAtIndex(nextStickyHeaderPosition.index);
      // 如果是同一组，返回
      if (currentStickyItem == nextItem) return;
      final scrollBox =
          _groupListKey.currentContext?.findRenderObject() as RenderBox;
      final stickHeaderBox =
          _stickyHeaderKey.currentContext?.findRenderObject() as RenderBox;
      final stickyHeaderHeight = stickHeaderBox.size.height;
      // print('nextHeaderKey $nextSection $_sectionHeaderKeys');
      final nextSectionBox = _sectionHeaderKeys[nextItem.rawSection]
          ?.currentContext
          ?.findRenderObject() as RenderBox;
      // 计算 nextSection 的位置，与 吸顶组件比较，更新吸顶组件的位置
      final position =
          nextSectionBox.localToGlobal(Offset.zero, ancestor: scrollBox);
      var stickyHeaderY = position.dy - stickyHeaderHeight;
      if (stickyHeaderY >= 0 || stickyHeaderY <= -stickyHeaderHeight) {
        stickyHeaderY = 0;
      }
      _stickyHeaderYStreamController.add(stickyHeaderY);
      // final height = nextSectionBox.size.height;
      // print('==== $stickyHeaderY');
      // print('nextSection ${nextItem.section} ${position.dy} $height');
    }
  }

  @override
  void didUpdateWidget(covariant StickyPositionedGroupList<S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dataSource != oldWidget.dataSource) {}
  }

  @override
  void initState() {
    super.initState();

    _stickyItemSubscription = _stickyItemStream.listen((item) {
      print('sticky header changed');
      _stickyItem = item;
      widget.onHeaderChanged?.call(item.rawSection);
      _stickyHeaderYStreamController.add(0);
    });

    _itemPositionsListener.itemPositions.addListener(_listenItemPositions);
  }

  DataSource<S, E> get dataSource => widget.dataSource;

  /// 构建分组头和分组下的 item
  Widget _buildWithWithItemWrapperIndex(BuildContext context, int index) {
    final wappedItem = dataSource.wrappedItemAtIndex(index);
    if (wappedItem.isSection) {
      return _buildSectionHeader(context, index, wappedItem.rawSection);
    }
    return _buildItem(context, wappedItem.rawItem);
  }

  /// 构建分组头
  Widget _buildSectionHeader(BuildContext context, int index, S section) {
    final key = _sectionHeaderKeys[section] ??=
        UniqueGlobalObjectKey(debugLabel: '$section');
    // print('$this build header $section $key $index');
    return Container(
      key: key,
      child: widget.headerBuilder(context, section),
    );
  }

  /// 构建分组下的 item
  Widget _buildItem(BuildContext context, E item) {
    return widget.itemBuilder(context, item);
  }

  Widget _buildStickyHeader(
      BuildContext context, AsyncSnapshot<double> snapshot) {
    return Positioned(
      key: _stickyHeaderKey,
      top: snapshot.data ?? 0,
      left: 0,
      right: 0,
      child: StreamBuilder<ItemWrapper>(
        builder: (context, snapshot) {
          final headerItem = snapshot.data!.rawSection;
          return Container(
            child: widget.headerBuilder(context, headerItem),
          );
        },
        initialData: _stickyItem,
        stream: _stickyItemStream,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ScrollablePositionedList.separated(
          key: _groupListKey,
          itemCount: dataSource.wrappedItemList.length,
          itemPositionsListener: _itemPositionsListener,
          itemScrollController: widget.itemScrollController,
          itemBuilder: _buildWithWithItemWrapperIndex,
          separatorBuilder:
              widget.separatorBuilder ?? (_, __) => const Offstage(),
        ), // 分组数据列表
        StreamBuilder(
          builder: _buildStickyHeader,
          stream: _stickyHeaderYStream,
          initialData: 0.0,
        ), // 吸顶头部
      ],
    );
  }
}

/// 数据源, S 分组数据模型， E 元素数据模型
class DataSource<S, E> {
  DataSource(this.rawDataSources, {this.sectionSorter})
      : assert(
            rawDataSources.isEmpty ||
                rawDataSources.keys.first is Comparable<S> ||
                sectionSorter != null,
            'sectionSorter must not be null if S is not Comparable');

  /// 将 [list] 按照 [keyForItem] 进行分组，再通过 [sectionSorter] 对分组进行排序。
  factory DataSource.fromList(
    List<E> list, {
    required S Function(E element) keyForItem,
    int Function(S key1, S key2)? sectionSorter,
    int Function(E e1, E e2)? itemsSorter,
  }) {
    final dataSources = <S, List<E>>{};
    for (var element in list) {
      final key = keyForItem(element);
      if (dataSources.containsKey(key)) {
        dataSources[key]!.add(element);
      } else {
        dataSources[key] = [element];
      }
    }
    if (itemsSorter != null || E is Comparable) {
      for (var list in dataSources.values) {
        list.sort(itemsSorter);
      }
    }
    return DataSource<S, E>(dataSources, sectionSorter: sectionSorter);
  }

  /// 分组排序函数
  final int Function(S key1, S key2)? sectionSorter;

  /// 原生数据模型， S 表示分组头的数据模型， List<E> 表示分组下的数据列表， E 表示每一行的数据模型
  final Map<S, List<E>> rawDataSources;

  /// 分组和分组下所有数据的集合
  List<ItemWrapper>? _wrappedItemList;

  /// 分组数据集合
  List<ItemWrapper>? _wrappedSectionItems;

  /// 排序后的原始分组数据集合
  List<S>? _sortedRawSections;

  /// 排序后的原始分组数据集合
  List<S> get sortedRawSections {
    if (rawDataSources.isEmpty) return [];
    _sortedRawSections ??= rawDataSources.keys.toList()..sort(sectionSorter);
    return _sortedRawSections!;
  }

  /// 将 Map<S, List<E>> 转换为 List<Item>。S 表示分组头数据，E 表示分组下的每一项数据，都包装在 Item 中。
  /// 在 [StickyPositionedGroupList] 中使用，方便区分是分组头还是分组下的每一项数据。
  List<ItemWrapper> get wrappedItemList {
    if (_wrappedItemList != null) return _wrappedItemList!;
    List<ItemWrapper> items = [];
    for (var section in sortedRawSections) {
      int sectionIndex = items.length;
      items.add(ItemWrapper(section,
          isSection: true,
          rawSection: section,
          index: sectionIndex,
          sectionIndex: sectionIndex));
      for (var element in (rawDataSources[section] ?? [])) {
        final index = items.length + 1;
        items.add(ItemWrapper(element,
            rawSection: section, sectionIndex: sectionIndex, index: index));
      }
    }
    _wrappedItemList = items;
    return items;
  }

  /// 计算所有元素数量，包含分组头数据和分组下的每一项数据
  int get numberOfWrappedItems => rawDataSources.values
      .map((list) => list.length + 1)
      .reduce((total, listLength) => total + listLength);

  /// 所有的分组数据模型
  List<ItemWrapper> get wrappedSectionItems {
    _wrappedSectionItems ??=
        wrappedItemList.where((item) => item.isSection).toList();
    return _wrappedSectionItems!;
  }

  /// 分组数量
  int get numberOfSections => rawDataSources.keys.length;

  /// 通过索引 [index] 获取包装后的数据
  ItemWrapper wrappedItemAtIndex(int index) {
    assert(index < numberOfWrappedItems,
        'index ($index) 不能超过总数量 numberOfWrappedItems ($numberOfWrappedItems)');
    return wrappedItemList[index];
  }

  ///通过 [index] 索引，获取该索引在 [wrappedItemList] 中的的分组的位置
  ItemWrapper findWrappedSectionItem(int index) {
    assert(index < numberOfWrappedItems,
        'index ($index) 不能超过总数量 numberOfWrappedItems (${wrappedItemList.length})');
    final item = wrappedItemList[index];
    return wrappedItemList[item.sectionIndex];
  }

  /// 通过原始分组数据查询包装后的分组数据
  int findWrappedSectionItemByRawSection(S section) {
    return wrappedItemList.indexWhere((element) => element.rawItem == section);
  }
}

/// 分组数据和分组下的行数据都包装在 ItemWrapper 中，方便在 [StickyPositionedGroupList] 中区分分组头和分组下的行数据。
class ItemWrapper<S, E> {
  const ItemWrapper(this.rawItem,
      {this.isSection = false,
      required this.rawSection,
      required this.index,
      required this.sectionIndex});

  /// 分组 或者 行数据的索引
  final int index;

  /// 所在分组索引
  final int sectionIndex;

  /// 是否是分组, true 表示是分组头数据， false 表示是分组下的行数据
  final bool isSection;

  /// 当 [isSection] 为 false 是， 表示是行数据; 否则为 null
  final E? rawItem;

  /// 所在分组的数据模型
  final S rawSection;
}
