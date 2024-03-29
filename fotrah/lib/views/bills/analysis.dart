import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/services/auth/auth_service.dart';
import 'package:fotrah/services/cloud/firebase_cloud_storage.dart';
import 'package:fotrah/enums/menu_action.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  TimeFrame selectedTimeFrame = TimeFrame.thisYear;
  int touchedIndex = -1;
  late final FirebaseCloudStorage _cloudStorage;
  late String _userId;
  List<PieChartSectionData> pieChartSections = [];
  List<FlSpot> lineChartSpots = [];
  List<BarChartGroupData> barChartGroups = [];
  double totalSpending = 0.0;
  double budget = 0.0;

  @override
  void initState() {
    super.initState();
    _cloudStorage = FirebaseCloudStorage();
    _userId = AuthService.firebase().currentUser?.email ?? '';
    _fetchAndBuildPieChart();
    updateTimeFrameData();
  }

  void setTimeFrame(TimeFrame frame) {
    setState(() {
      selectedTimeFrame = frame;
    });
    updateTimeFrameData();
  }

  void updateTimeFrameData() async {
    double newTotalSpending = await _cloudStorage.getTotalSpendingForTimeFrame(
        selectedTimeFrame, _userId);
    double newBudget =
        await _cloudStorage.getBudgetForTimeFrame(selectedTimeFrame, _userId);
    List<BarChartGroupData> newBarChartGroups = await _cloudStorage
        .getSpendingDataBasedOnTimeFrame(_userId, selectedTimeFrame);

    setState(() {
      totalSpending = newTotalSpending;
      budget = newBudget;
      barChartGroups = newBarChartGroups;
    });

    _fetchAndBuildPieChart();
    lineChartSpots = await _cloudStorage.getTotalSpendingOverTime(
        _userId, selectedTimeFrame);
  }

  Future<void> _fetchAndBuildPieChart() async {
    final spendingPerCategory = await _cloudStorage
        .getTotalSpendingPerCategoryForUser(_userId, selectedTimeFrame);
    _updatePieChartSections(spendingPerCategory);
  }

  void _updatePieChartSections(Map<String, double> spendingPerCategory) {
    final sections = _pieChartSections(spendingPerCategory);
    setState(() {
      pieChartSections = sections;
    });
  }

  List<PieChartSectionData> _pieChartSections(
      Map<String, double> spendingPerCategory) {
    final isNotEmpty = spendingPerCategory.values.any((value) => value > 0);
    if (!isNotEmpty) {
      return [];
    }
    final totalSpending =
        spendingPerCategory.values.fold(0.0, (sum, item) => sum + item);
    return spendingPerCategory.entries.map((entry) {
      final categoryPercentage = (entry.value / totalSpending) * 100;
      return PieChartSectionData(
        color: _getColorForCategory(entry.key),
        value: categoryPercentage,
        title: '${entry.key}\n${categoryPercentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xffffffff)),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  Color _getColorForCategory(String category) {
    const categoryColors = <String, Color>{
      "Housing": Colors.red,
      "Utilities": Colors.green,
      "Transportation": Colors.blue,
      "Groceries": Colors.orange,
      "Dining Out": Colors.purple,
      "Healthcare": Colors.yellow,
      "Entertainment": Colors.cyan,
      "Personal Care": Colors.brown,
      "Clothing": Colors.pink,
      "Education": Colors.lime,
      "Childcare": Colors.indigo,
      "Pets": Colors.teal,
      "Savings and Investments": Colors.grey,
      "Gifts and Donations": Colors.amber,
      "Travel": Colors.deepOrange,
      "Debts": Colors.blueGrey,
      "Other": Colors.lightBlue,
    };

    return categoryColors[category] ?? Colors.black; // Fallback color
  }

  Map<String, Color> categoryColors = {
    "Housing": Colors.red,
    "Utilities": Colors.green,
    "Transportation": Colors.blue,
    "Groceries": Colors.orange,
    "Dining Out": Colors.purple,
    "Healthcare": Colors.yellow,
    "Entertainment": Colors.cyan,
    "Personal Care": Colors.brown,
    "Clothing": Colors.pink,
    "Education": Colors.lime,
    "Childcare": Colors.indigo,
    "Pets": Colors.teal,
    "Savings & Investments": Colors.grey,
    "Gifts & Donations": Colors.amber,
    "Travel": Colors.deepOrange,
    "Debts": Colors.blueGrey,
    "Other": Colors.lightBlue,
  };

  List<Widget> generateLegendWidgets() {
    List<Widget> legendWidgets = [];
    categoryColors.forEach((category, color) {
      legendWidgets.add(
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(category),
          ],
        ),
      );
      legendWidgets.add(SizedBox(height: 4)); // Spacer between legend items
    });
    return legendWidgets;
  }

  Widget _getMonthTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    String text = '';
    if (value.toInt() >= 1 && value.toInt() <= 12) {
      text = months[value.toInt() - 1];
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8, // You can adjust the space as needed
      child: Text(text, style: style),
    );
  }

  Widget _getDayTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    // You might maintain a set of already used dates as a member of the class to check against.
    Set<int> usedDays = Set();

    // Calculate the actual date using the year, month, and value as the day.
    DateTime now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, value.toInt());
    String dayOfWeek = DateFormat('EEE').format(date);

    // If we've already used this day, return an empty container.
    if (usedDays.contains(value.toInt())) {
      return Container(); // This will effectively hide the title for this day.
    } else {
      // Otherwise, add the day to the set of used days and return the widget.
      usedDays.add(value.toInt());
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 8,
        child: Text(dayOfWeek, style: style),
      );
    }
  }

  Widget _getSpendingTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    return Text('\$$value',
        style: style); // Assuming the spending value fits well
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Analysis",
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 10,
        shadowColor: Colors.blueAccent.shade100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent.shade700],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ToggleButton(
                    title: 'All Time',
                    selectedTimeFrame: selectedTimeFrame,
                    timeFrame: TimeFrame.AllTime,
                    onPressed: () => setTimeFrame(TimeFrame.AllTime),
                  ),
                  ToggleButton(
                    title: 'This year',
                    selectedTimeFrame: selectedTimeFrame,
                    timeFrame: TimeFrame.thisYear,
                    onPressed: () => setTimeFrame(TimeFrame.thisYear),
                  ),
                  ToggleButton(
                    title: 'This Month',
                    selectedTimeFrame: selectedTimeFrame,
                    timeFrame: TimeFrame.thisMonth,
                    onPressed: () => setTimeFrame(TimeFrame.thisMonth),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                DisplayCard(title: 'Total Spending', value: totalSpending),
                DisplayCard(title: 'Budget', value: budget),
              ],
            ),
            //PieChart begin
            Container(
              height: 320,
              child: Card(
                elevation: 4.0,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3, // Give more space to the pie chart
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sections: pieChartSections.map((section) {
                              final isTouched =
                                  pieChartSections.indexOf(section) ==
                                      touchedIndex;
                              final fontSize = isTouched ? 18.0 : 16.0;
                              final radius = isTouched ? 60.0 : 50.0;
                              return PieChartSectionData(
                                color: section.color,
                                value: section.value,
                                title: section.title,
                                radius: radius,
                                titleStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              );
                            }).toList(), // Your dynamic section data here
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2, // Allocate more space for the legend
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(),
                            child: Column(
                              children: [
                                // Your dynamic legend items here
                                for (var i = 0;
                                    i < pieChartSections.length;
                                    i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0),
                                    child: Indicator(
                                      color: pieChartSections[i].color,
                                      text: pieChartSections[i].title,
                                      isSquare: true,
                                      textStyle: const TextStyle(
                                          fontSize: 10.9), // Smaller text size
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //PieChart end
            //LineChart begin
            Card(
              elevation: 2.0,
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "Spending Over Time",
                      style: Theme.of(context).textTheme.headline6,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    AspectRatio(
                      aspectRatio: 1.55, // You can adjust the aspect ratio
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: const FlTitlesData(show: true),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: lineChartSpots,
                              isCurved: false,
                              color: Colors
                                  .blue, // Specify a single color if not using gradient
                              barWidth: 5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                applyCutOffY: true,
                              ),
                              // If you want a gradient, you can use the gradient parameter like so:
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.blue,
                                  Colors.blueAccent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            //LineChart end
            // BarChart begin
            Card(
              elevation: 4.0,
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "Monthly or daily Spending Comparison",
                      style: Theme.of(context).textTheme.headline6,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    AspectRatio(
                      aspectRatio: 1.55,
                      child: BarChart(
                        BarChartData(
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.blueGrey,
                              getTooltipItem: (_a, _b, _c, _d) => null,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    selectedTimeFrame == TimeFrame.thisMonth
                                        ? _getDayTitles
                                        : _getMonthTitles,
                                reservedSize: 28,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: _getSpendingTitles,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: barChartGroups,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // BarChart end
          ],
        ),
      ),
    );
  }
}

class BarChartContainer extends StatelessWidget {
  final List<BarChartGroupData> barGroups;

  const BarChartContainer({
    Key? key,
    required this.barGroups,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20,
          barGroups: barGroups,
          titlesData: const FlTitlesData(
            // Adjusted to use AxisTitles
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
        ),
      ),
    );
  }
}

class DisplayCard extends StatelessWidget {
  final String title;
  final double value;

  const DisplayCard({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("\$${value.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// The ToggleButton is a stateless widget that you can use to switch between time frames:
class ToggleButton extends StatelessWidget {
  final String title;
  final TimeFrame timeFrame;
  final VoidCallback onPressed;
  final TimeFrame selectedTimeFrame;

  const ToggleButton({
    Key? key,
    required this.title,
    required this.onPressed,
    required this.timeFrame,
    required this.selectedTimeFrame,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedTimeFrame == timeFrame;

    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 38.0, vertical: 10.0),
        textStyle: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final TextStyle textStyle; // Add the textStyle parameter

  const Indicator({
    Key? key,
    required this.color,
    required this.text,
    this.isSquare = false,
    this.textStyle = const TextStyle(fontSize: 14), // Provide a default style
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: isSquare ? 16 : 12,
          height: isSquare ? 16 : 12,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: textStyle), // Use the textStyle parameter here
      ],
    );
  }
}
