import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_exchange/constants.dart';
import 'package:my_exchange/provider/home_provider.dart';
import 'package:my_exchange/screen/chart_screen.dart';
import 'package:my_exchange/screen/translate_screen.dart';
import 'package:provider/provider.dart';

import 'package:tuple/tuple.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  void _showUnitDialog(BuildContext originContext) {
    final provider = originContext.read<HomeProvider>();
    showModalBottomSheet(
      context: originContext,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < availableUnits.length; i++)
                InkWell(
                  borderRadius: i == 0
                      ? BorderRadius.vertical(top: Radius.circular(28))
                      : i == availableUnits.length - 1
                      ? BorderRadius.vertical(bottom: Radius.circular(8))
                      : null,
                  onTap: () {
                    provider.setCurrentUnit(availableUnits[i]);
                    Navigator.pop(context);
                  },
                  child: _UnitItem(
                    unit: availableUnits[i],
                    selected: provider.currentUnit == availableUnits[i],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(),
      builder: (context, child) {
        // final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('환율 계산기'),
                const SizedBox(width: 8),
                if (context.select<HomeProvider, bool>(
                  (value) => value.isLoading,
                ))
                  const _RefreshIcon(),
              ],
            ),
            centerTitle: false,
            // leading:
            //     context.select<HomeProvider, bool>((value) => value.isLoading)
            //         ? const _RefreshIcon()
            //         : null,
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TranslateScreen(),
                  ),
                ),
                icon: const Icon(Icons.g_translate),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChartScreen()),
                ),
                icon: const Icon(Icons.bar_chart),
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    spacing: 16,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!context.select<HomeProvider, bool>(
                              (value) => value.isLoading,
                            ))
                              Text(
                                '발표: ${DateFormat('MM월 dd일').format(context.select<HomeProvider, DateTime>((value) => value.date))}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            Text(
                              '환율: ${context.select<HomeProvider, String>((value) => value.rate.toStringAsFixed(2))} 원',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
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
                                    value.item2 ? "KRW" : value.item1,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.swap_horizontal_circle,
                                    ),
                                    onPressed: () => context
                                        .read<HomeProvider>()
                                        .toggleReverse(),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    value.item2 ? value.item1 : "KRW",
                                    style: const TextStyle(fontSize: 18),
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
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                padding: const EdgeInsets.only(
                                  right: 5,
                                  left: 16,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    context.select<HomeProvider, String>(
                                      (value) => value.currentUnit,
                                    ),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                                onTab: () => context
                                    .read<HomeProvider>()
                                    .addPrice(amount),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemCount: value
                                ? reverseShortcuts.length
                                : shortcuts.length,
                          ),
                        ),
                        selector: (p0, p1) => p1.isReverse,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: context
                              .select<HomeProvider, TextEditingController>(
                                (value) => value.textController,
                              ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CommaSeparatorInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: "원하시는 금액을 입력하세요.",
                            suffix: Text(
                              context.select<HomeProvider, bool>(
                                    (value) => value.isReverse,
                                  )
                                  ? 'KRW'
                                  : context.select<HomeProvider, String>(
                                      (value) => value.currentUnit,
                                    ),
                            ),
                            suffixIcon:
                                context.select<HomeProvider, bool>(
                                  (value) => value.textController.text.isEmpty,
                                )
                                ? null
                                : IconButton(
                                    onPressed: () => context
                                        .read<HomeProvider>()
                                        .clearInput(),
                                    icon: const Icon(Icons.cancel),
                                  ),
                          ),
                          textInputAction: TextInputAction.done,
                          onChanged:
                              context.select<HomeProvider, bool>(
                                (value) => value.isLoading,
                              )
                              ? null
                              : (_) => context
                                    .read<HomeProvider>()
                                    .onInputChanged(),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Center(
                            child:
                                Selector<
                                  HomeProvider,
                                  Tuple3<bool, String, int>
                                >(
                                  builder: (context, value, child) => Text(
                                    '${NumberFormat("###,###,###").format(value.item3)} ${value.item1 ? value.item2 : "원"}',
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  selector: (p0, p1) => Tuple3(
                                    p1.isReverse,
                                    p1.currentUnit,
                                    p1.totalAmount,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (context.select<HomeProvider, bool>(
                  (value) => value.hasError,
                ))
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.red,
                      child: Row(
                        children: [
                          Expanded(
                            child: const Text(
                              "환율정보 불러오기에 실패했습니다.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                context.read<HomeProvider>().reload(),
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShortcutPrice extends StatelessWidget {
  const _ShortcutPrice({required this.amount, required this.onTab});

  final int amount;
  final void Function() onTab;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        side: const BorderSide(color: Colors.blueAccent),
        textStyle: const TextStyle(fontSize: 14, color: Colors.blueAccent),
      ),
      onPressed: onTab,
      child: Text("+ ${NumberFormat("###,###,###").format(amount)}"),
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
          Text(unit, style: const TextStyle(fontSize: 20)),
          if (selected) ...[const SizedBox(width: 20), const Icon(Icons.done)],
        ],
      ),
    );
  }
}

class CommaSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ",";

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    super.initState();
    _controller.repeat();
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
