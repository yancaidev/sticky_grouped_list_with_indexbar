import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sticky_grouped_list_with_indexbar/sticky_grouped_list_with_indexbar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Map<String, List<String>> rawDataSource = {};

  late DataSource<String, String> dataSource =
      DataSource<String, String>(rawDataSource);

  late ItemScrollController itemScrollController = ItemScrollController();

  late final StreamController<String> _sectionController = StreamController();
  Stream<String>? _sectionStream;

  @override
  void initState() {
    super.initState();
    rawDataSource['A'] = ['A1', 'A2', 'A3'];
    rawDataSource['B'] = ['B1', 'B2', 'B3', 'B4'];
    rawDataSource['C'] = ['C1', 'C2', 'C3', 'C4', 'C5'];
    rawDataSource['D'] = ['D1', 'D2', 'D3', 'D4', 'D5', 'D6'];
    rawDataSource['E'] = ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7'];
    rawDataSource['F'] = ['F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8'];
    rawDataSource['G'] = ['G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7', 'G8', 'G9'];
    rawDataSource['H'] = ['H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'H7', 'H8'];
    rawDataSource['I'] = ['I1', 'I2', 'I3', 'I4', 'I5', 'I6', 'I7'];
    rawDataSource['J'] = ['J1', 'J2', 'J3', 'J4', 'J5', 'J6'];
    rawDataSource['K'] = ['K1', 'K2', 'K3', 'K4', 'K5'];
    rawDataSource['L'] = ['L1', 'L2', 'L3', 'L4'];
    rawDataSource['M'] = ['M1', 'M2', 'M3'];
    _sectionStream =  _sectionController.stream.asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(title: const Text('StickyGroupedListView')),
      body: Stack(
        children: [
          StickyPositionedGroupList<String, String>(
            dataSource: dataSource,
            itemScrollController: itemScrollController,
            headerBuilder: (context, item) => Container(
              alignment: Alignment.centerLeft,
              height: 30,
              color: Colors.blue,
              child: Text(item),
            ),
            itemBuilder: (context, item) => Container(
              alignment: Alignment.centerLeft,
              height: 50,
              child: Text(item),
            ),
            onHeaderChanged: (section) {
              _sectionController.add(section);
            },
          ),

          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IndexBar<String>(
              backgroundColor: Colors.grey.withOpacity(0.1),
              items: dataSource.sortedRawSections,
              itemBuilder: (context, index, item, isSelected) {
                return StreamBuilder(
                  builder: (context, snapshot) {
                    final currentIndex =
                        dataSource.sortedRawSections.indexOf(snapshot.data!);
                    final selected = currentIndex == index;
                    print('$item $index $isSelected $currentIndex');
                    final color = selected ? Colors.red : Colors.black;
                    return Text(item, style: TextStyle(color: color));
                  },
                  initialData: dataSource.sortedRawSections.first,
                  stream: _sectionStream,
                );
              },
              defaultIndicatorBuilder: (context, index, selectedItem) => Text(
                selectedItem ?? '',
                style: const TextStyle(color: Colors.white),
              ),
              onSelectedItemChanged: (item, index) {
                itemScrollController.scrollTo(
                    index: dataSource.findWrappedSectionItemByRawSection(item),
                    duration: Duration.zero);
              },
            ),
          ), // IndexBar 放置在右侧，居中
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _incrementCounter() {}
}
