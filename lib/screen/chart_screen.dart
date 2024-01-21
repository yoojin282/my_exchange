import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_exchange/constants.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/model/db_models.dart';
import 'package:my_exchange/service/exchange_service.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final _service = getIt<ExchangeService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("환율변동 그래프"),
      ),
      body: SafeArea(
        child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              return FutureBuilder(
                future: _service.getCurrenciesByUnit(availableUnits[index]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return _ChartItem(
                    unit: availableUnits[index],
                    data: snapshot.requireData,
                  );
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemCount: availableUnits.length),
      ),
    );
  }
}

class _ChartItem extends StatelessWidget {
  const _ChartItem({required this.unit, required this.data});

  final String unit;
  final List<CurrencyDB> data;

  LineChartData _createChartData() {
    int index = 0;
    double maxY = 0;
    double minY = double.maxFinite;
    List<FlSpot> spots = [];
    List<DateTime> dates = [];

    for (final item in data) {
      final rate = item.rate.toDouble();
      spots.add(FlSpot((index++).toDouble(), rate));
      dates.add(item.date);
      maxY = max(maxY, rate);
      minY = min(minY, rate);
    }

    maxY *= 1.05;
    minY *= 0.95;

    final barData = LineChartBarData(
      isCurved: true,
      color: Colors.amber,
      barWidth: 5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      spots: spots,
    );
    return LineChartData(
      lineBarsData: [barData],
      minY: minY.toInt().toDouble(),
      maxY: maxY.toInt().toDouble(),
      minX: 0,
      maxX: dates.length - 1,
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      backgroundColor: Colors.black12,
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              if (unit == 'USD') {
                print('$maxY, $value');
              }
              if (maxY == value || minY == value) return const SizedBox();
              if (value %
                      (maxY > 100
                          ? 1
                          : maxY > 1000
                              ? 10
                              : 1) ==
                  0) {
                return Text(value.toInt().toString());
              }

              // return Text(value.toInt().toString());
              return const SizedBox();
            },
          )),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) =>
                Text('${dates[value.toInt()].day}일'),
          ))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.blueGrey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Column(
          children: [
            Text(unit),
            const SizedBox(height: 8),
            AspectRatio(aspectRatio: 1.5, child: LineChart(_createChartData())),
          ],
        ),
      ),
    );
  }
}
