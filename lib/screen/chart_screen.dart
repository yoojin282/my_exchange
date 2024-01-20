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

  Future<LineChartData> _createChartData(String unit) async {
    List<CurrencyDB> currencies = await _service.getCurrenciesByUnit(unit);

    int index = 0;
    double maxY = 0;
    double minY = double.maxFinite;
    List<FlSpot> spots = [];
    List<DateTime> dates = [];
    for (final item in currencies) {
      spots.add(FlSpot((index++).toDouble(), item.rate));
      dates.add(item.date);
      maxY = max(maxY, item.rate);
      minY = min(minY, item.rate);
    }

    maxY *= 1.05;
    minY *= 0.95;

    final barData = LineChartBarData(
      isCurved: true,
      color: Colors.amber,
      barWidth: 8,
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
            getTitlesWidget: (value, meta) {
              if (value % 1 == 0) return Text(value.toInt().toString());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("환율변동 그래프"),
      ),
      body: SafeArea(
        child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              return AspectRatio(
                aspectRatio: 1.5,
                child: FutureBuilder(
                  future: _createChartData(availableUnits[index]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) return Text('${snapshot.error}');
                    return LineChart(snapshot.requireData);
                  },
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemCount: availableUnits.length),
      ),
    );
  }
}
