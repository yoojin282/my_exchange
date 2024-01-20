import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_exchange/provider/home_provider.dart';
import 'package:provider/provider.dart';

import 'package:tuple/tuple.dart';

const List<String> availableUnits = ['USD', 'THB', "JPY(100)"];
const shortcuts = [20, 100, 500, 1000, 5000];
const reverseShortcuts = [1000, 5000, 10000, 50000, 100000];

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  void _showUnitDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var unit in availableUnits)
              InkWell(
                onTap: () {
                  // _changeUnit(unit);
                  Navigator.pop(context);
                },
                child: _UnitItem(
                  unit: unit,
                  selected: false,
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(),
      builder: (context, child) => Scaffold(
        appBar: AppBar(
          title: const Text("환율여행"),
          centerTitle: true,
          actions: [
            if (context
                .select<HomeProvider, bool>((value) => value.isLoading)) ...[
              const _RefreshIcon(),
              const SizedBox(
                width: 16,
              ),
            ]
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!context.select<HomeProvider, bool>(
                              (value) => value.isLoading))
                            Text(
                              '환율발표: ${DateFormat('MM월 dd일').format(
                                context.select<HomeProvider, DateTime>(
                                    (value) => value.date),
                              )}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          Text(
                            '환율: ${context.select<HomeProvider, double>((value) => value.rate)} 원',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Selector<HomeProvider, Tuple2<String, bool>>(
                            builder: (context, value, child) => Row(
                              children: [
                                Text(
                                  value.item2
                                      ? "KRW"
                                      : value.item1.replaceAll("(100)", ""),
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.swap_horizontal_circle),
                                  onPressed: () => context
                                      .read<HomeProvider>()
                                      .toggleReverse(),
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  value.item2
                                      ? value.item1.replaceAll("(100)", "")
                                      : "KRW",
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            selector: (p0, p1) =>
                                Tuple2(p1.currentUnit, p1.isReverse),
                          ),
                          OutlinedButton(
                            onPressed: () => _showUnitDialog(context),
                            style: OutlinedButton.styleFrom(
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              padding:
                                  const EdgeInsets.only(right: 5, left: 16),
                            ),
                            child: Row(children: [
                              Text(
                                context
                                    .select<HomeProvider, String>(
                                        (value) => value.currentUnit)
                                    .replaceAll("(100)", ""),
                                style: const TextStyle(fontSize: 18),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                              ),
                            ]),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Selector<HomeProvider, bool>(
                      builder: (context, value, child) => SizedBox(
                        height: 30,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            int amount = value
                                ? reverseShortcuts[index]
                                : shortcuts[index];
                            return _ShortcutPrice(
                              amount: amount,
                              onTab: () =>
                                  context.read<HomeProvider>().addPrice(amount),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemCount: value
                              ? reverseShortcuts.length
                              : shortcuts.length,
                        ),
                      ),
                      selector: (p0, p1) => p1.isReverse,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: context
                                  .select<HomeProvider, TextEditingController>(
                                      (value) => value.textController),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CommaSeparatorInputFormatter(),
                              ],
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                  hintText: "원하시는 금액을 입력하세요.",
                                  suffix: Text(
                                      context.select<HomeProvider, bool>(
                                              (value) => value.isReverse)
                                          ? 'KRW'
                                          : context
                                              .select<HomeProvider, String>(
                                                  (value) => value.currentUnit)
                                              .replaceAll("(100)", "")),
                                  suffixIcon: context
                                          .select<HomeProvider, bool>((value) =>
                                              value.textController.text.isEmpty)
                                      ? null
                                      : IconButton(
                                          onPressed: () => context
                                              .read<HomeProvider>()
                                              .clearInput(),
                                          icon: const Icon(
                                            Icons.cancel,
                                          ),
                                        )),
                              textInputAction: TextInputAction.done,
                              onChanged: context.select<HomeProvider, bool>(
                                      (value) => value.isLoading)
                                  ? null
                                  : (_) => context
                                      .read<HomeProvider>()
                                      .onInputChanged(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child:
                              Selector<HomeProvider, Tuple3<bool, String, int>>(
                            builder: (context, value, child) => Text(
                              '${value.item3} ${value.item1 ? value.item2.replaceAll("(100)", "") : '원'}',
                              style: const TextStyle(fontSize: 48),
                            ),
                            selector: (p0, p1) => Tuple3(
                                p1.isLoading, p1.currentUnit, p1.totalAmount),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (context.select<HomeProvider, bool>((value) => value.hasError))
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: SnackBar(
                    content: Text("환율정보 불러오기에 실패했습니다. 잠시후 다시 시도해 주세요."),
                    duration: Duration(seconds: 5),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutPrice extends StatelessWidget {
  const _ShortcutPrice({
    required this.amount,
    required this.onTab,
  });

  final int amount;
  final void Function() onTab;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 10,
        ),
        side: const BorderSide(
          color: Colors.blueAccent,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.blueAccent,
        ),
      ),
      onPressed: onTab,
      child: Text(
        "+ ${NumberFormat("###,###,###").format(amount)}",
      ),
    );
  }
}

class _UnitItem extends StatelessWidget {
  const _UnitItem({required this.unit, required this.selected});

  final String unit;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        child: Row(
          children: [
            Text(
              unit,
              style: const TextStyle(fontSize: 20),
            ),
            if (selected) ...[
              const SizedBox(
                width: 20,
              ),
              const Icon(
                Icons.done,
              ),
            ]
          ],
        ));
  }
}

class CommaSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ",";

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: "");
    }

    String oldValueText = oldValue.text.replaceAll(separator, '');
    String newValueText = newValue.text.replaceAll(separator, '');
    if (oldValue.text.endsWith(separator) &&
        oldValue.text.length == newValue.text.length + 1) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }

    // Only process if the old value and new value are different
    if (oldValueText != newValueText) {
      int selectionIndex =
          newValue.text.length - newValue.selection.extentOffset;
      final chars = newValueText.split('');

      String newString = '';
      for (int i = chars.length - 1; i >= 0; i--) {
        if ((chars.length - 1 - i) % 3 == 0 && i != chars.length - 1) {
          newString = separator + newString;
        }
        newString = chars[i] + newString;
      }

      return TextEditingValue(
        text: newString.toString(),
        selection: TextSelection.collapsed(
          offset: newString.length - selectionIndex,
        ),
      );
    }
    return newValue;
  }
}

class _RefreshIcon extends StatefulWidget {
  const _RefreshIcon();

  @override
  State<_RefreshIcon> createState() => __RefreshIconState();
}

class __RefreshIconState extends State<_RefreshIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
      child: const Icon(Icons.loop),
    );
  }
}
