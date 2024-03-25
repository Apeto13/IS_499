import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fotrah/services/auth/auth_service.dart';
import 'package:fotrah/services/cloud/firebase_cloud_storage.dart';
import 'package:fotrah/enums/menu_action.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  TimeFrame selectedTimeFrame = TimeFrame.monthly;
  double totalSpending = 0.0;
  double budget = 0.0;
  int touchedIndex = -1;
  late final FirebaseCloudStorage _cloudStorage;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _cloudStorage = FirebaseCloudStorage(); // Initialize _cloudStorage here
    _userId = AuthService.firebase().currentUser?.email ??
        ''; // Make sure to handle the case where email might be null
    updateTimeFrameData(); // Now it's safe to call this since _cloudStorage is initialized
  }

  void setTimeFrame(TimeFrame frame) {
    final _userId = AuthService.firebase().currentUser?.email;
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
    setState(() {
      totalSpending = newTotalSpending;
      budget = newBudget;
    });
  }

  Future<Map<String, double>> fetchAndCalculateTotalsByCategory(
      String userId, TimeFrame timeframe) async {
    // Your logic here to fetch bills from Firestore based on the userId and timeframe
    // For example, you fetch all bills for the user within the selected timeframe
    // Then, aggregate totals by category
    Map<String, double> categoryTotals = {};

    // Example of what you might do (this is pseudocode and won't run directly)
    final bills = await FirebaseFirestore.instance
        .collection('bills')
        // Your query here to fetch bills based on the timeframe
        .get();

    for (var bill in bills.docs) {
      String category =
          bill.data()['category']; // Assuming each bill has a 'category' field
      double total =
          bill.data()['total']; // Assuming each bill has a 'total' field

      // Aggregate totals by category
      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = (categoryTotals[category] ?? 0) + total;
      } else {
        categoryTotals[category] = total;
      }
    }

    return categoryTotals;
  }

  Future<List<PieChartSectionData>> generatePieSections(
      String userId, TimeFrame timeframe) async {
    Map<String, double> totalsByCategory =
        await fetchAndCalculateTotalsByCategory(userId, timeframe);

    List<PieChartSectionData> sections = [];
    totalsByCategory.forEach((category, total) {
      // Convert each category and its total into a section of the pie chart
      // You would also assign a color to each section here
      // This is an example, you need to adjust it based on your actual categories and desired colors
      sections.add(PieChartSectionData(
        color:
            Colors.blue, // You'd likely want a way to dynamically assign colors
        value: total,
        title: '$total',
        // Additional styling as needed
      ));
    });

    return sections;
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.blue,
            value: 40,
            title: '40%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.yellow,
            value: 30,
            title: '30%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Colors.purple,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 3:
          return PieChartSectionData(
            color: Colors.green,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  final List<BarChartGroupData> barGroups = [
    BarChartGroupData(x: 0, barRods: [
      BarChartRodData(toY: 8, color: Colors.blue, width: 15),
    ]),
    BarChartGroupData(x: 1, barRods: [
      BarChartRodData(toY: 10, color: Colors.orangeAccent, width: 15),
    ]),
    BarChartGroupData(x: 2, barRods: [
      BarChartRodData(toY: 14, color: Colors.redAccent, width: 15),
    ]),
    BarChartGroupData(x: 3, barRods: [
      BarChartRodData(toY: 5, color: Colors.greenAccent, width: 15),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Toggle buttons for selecting the time frame
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ToggleButton(
                    title: 'Yearly',
                    selectedTimeFrame: selectedTimeFrame,
                    timeFrame: TimeFrame.yearly,
                    onPressed: () => setTimeFrame(TimeFrame.yearly),
                  ),
                  ToggleButton(
                    title: 'Monthly',
                    selectedTimeFrame: selectedTimeFrame,
                    timeFrame: TimeFrame.monthly,
                    onPressed: () => setTimeFrame(TimeFrame.monthly),
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

            // Horizontal layout for Total, Budget and Pie Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                DisplayCard(title: 'Total Spending', value: totalSpending),
                DisplayCard(title: 'Budget', value: budget),
              ],
            ),

            Container(
              height: 320, // Adjust the height to fit the chart and indicators
              child: Card(
                elevation: 4.0,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(
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
                            sections: showingSections(),
                            sectionsSpace: 1,
                            centerSpaceRadius: 40,
                          ),
                          swapAnimationDuration:
                              Duration(milliseconds: 150), // Optional
                          swapAnimationCurve: Curves.linear, // Optional
                        ),
                      ),
                      // Indicators
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            Indicator(
                                color: Colors.red,
                                text: 'Category 1',
                                isSquare: true),
                            SizedBox(height: 4),
                            Indicator(
                                color: Colors.green,
                                text: 'Category 2',
                                isSquare: true),
                            // Add more indicators as needed
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Container for Bar Chart to ensure it has size
            Card(
              elevation: 4.0,
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 200, // Set a fixed height
                  child: BarChart(
                    BarChartData(
                      titlesData: FlTitlesData(show: false), // Hide the titles
                      borderData: FlBorderData(show: false), // Hide the borders
                      barGroups: barGroups,
                    ),
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
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16)),
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
  final TimeFrame selectedTimeFrame; // Add this line

  const ToggleButton({
    Key? key,
    required this.title,
    required this.onPressed,
    required this.timeFrame,
    required this.selectedTimeFrame, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedTimeFrame == timeFrame; // Use it here

    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey,
        shape: const StadiumBorder(),
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  const Indicator({
    Key? key,
    required this.color,
    required this.text,
    this.isSquare = false,
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
        Text(text, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
