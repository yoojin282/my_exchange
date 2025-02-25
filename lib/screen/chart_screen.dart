import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      appBar: AppBar(title: const Text("환율변동 그래프")),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          clipBehavior: Clip.none,
          itemBuilder: (context, index) {
            return FutureBuilder(
              future: _service.getCurrenciesByUnit(availableUnits[index]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _ChartItem(
                  unit: availableUnits[index],
                  data: snapshot.requireData,
                );
              },
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemCount: availableUnits.length,
        ),
      ),
    );
  }
}

class _ChartItem extends StatelessWidget {
  _ChartItem({required this.unit, required this.data});

  final String unit;
  final List<CurrencyDB> data;

  final List<Color> _gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

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

    maxY = (maxY * 1.05).toInt().toDouble();
    minY = (minY * 0.95).toInt().toDouble();

    final barData = LineChartBarData(
      isCurved: true,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: true),
      gradient: LinearGradient(colors: _gradientColors),
      spots: spots,
    );
    return LineChartData(
      lineBarsData: [barData],
      minY: minY,
      maxY: maxY,
      minX: 0,
      maxX: dates.length - 1,
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      gridData: const FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            getTitlesWidget: (value, meta) {
              if (value == minY || value == maxY) return const SizedBox();
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Color(0xff67727d),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value % 2 != 0) return const SizedBox();
              return Text(
                DateFormat('MM.dd').format(dates[value.toInt()]),
                style: const TextStyle(
                  color: Color(0xff67727d),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: const Color(0xff222e38),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10,
          left: 20,
          bottom: 10,
          right: 40,
        ),
        child: Column(
          children: [
            Text(unit, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            AspectRatio(aspectRatio: 1.5, child: LineChart(_createChartData())),
          ],
        ),
      ),
    );
  }
}
