import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class ComparisonGraphScreen extends StatelessWidget {
  final Map<String, dynamic> predictionResults;
  final String dataset;

  const ComparisonGraphScreen({
    Key? key,
    required this.predictionResults,
    required this.dataset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the first (and only) algorithm result
    final String modelName = predictionResults.keys.first;
    final result = predictionResults[modelName];

    final bool hasActualCounts = result.containsKey('actual_counts');
    final List<dynamic> infectedIps = result['infected_ips'] ?? [];
    final List<dynamic> uniqueInfectedSources =
        result['unique_infected_sources'] ?? [];

    // Debug print to verify the data
    print('DEBUG - uniqueInfectedSources: $uniqueInfectedSources');
    print('DEBUG - Full result: $result');

    // Get the maximum value for the y-axis
    double maxY = 0;
    result['counts'].values.forEach((v) {
      if (v > maxY) maxY = v.toDouble();
    });

    if (hasActualCounts) {
      result['actual_counts'].values.forEach((v) {
        if (v > maxY) maxY = v.toDouble();
      });
    }

    // Format model name
    String displayName = modelName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    // Get prediction counts
    final int normalPredicted = result['counts']['0'] ?? 0;
    final int botPredicted = result['counts']['1'] ?? 0;
    final int totalPredicted = normalPredicted + botPredicted;

    // Get actual counts if available
    int normalActual = 0;
    int botActual = 0;
    int totalActual = 0;

    if (hasActualCounts) {
      normalActual = result['actual_counts']['0'] ?? 0;
      botActual = result['actual_counts']['1'] ?? 0;
      totalActual = normalActual + botActual;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('$displayName Results'),
        backgroundColor: AppTheme.cardDark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Debug card to directly show the unique infected sources
              Card(
                color: Colors.red.shade900,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEBUG - Unique Infected Sources (${uniqueInfectedSources.length}):',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        uniqueInfectedSources.isEmpty
                            ? 'No unique infected sources found'
                            : uniqueInfectedSources.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with dataset info
              Card(
                color: AppTheme.cardDark,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dataset,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bot Detection Analysis',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ],
                          ),
                          if (result['accuracy'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getAccuracyColor(result['accuracy']),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Accuracy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                  ),
                                  Text(
                                    '${(result['accuracy'] * 100).toStringAsFixed(2)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Unique Infected Source IPs section moved to the top for visibility
              Card(
                color: AppTheme.cardDark,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Unique Infected Source IPs',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${uniqueInfectedSources.length} Sources',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: uniqueInfectedSources.isEmpty
                            ? const Text(
                                'No unique infected sources found',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Builder(
                                builder: (context) {
                                  try {
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: uniqueInfectedSources
                                          .map<Widget>((ip) {
                                        try {
                                          return Chip(
                                            backgroundColor: AppTheme
                                                .accentColor
                                                .withOpacity(0.15),
                                            side: BorderSide(
                                              color: AppTheme.accentColor
                                                  .withOpacity(0.3),
                                            ),
                                            label: Text(
                                              ip.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            avatar: const Icon(
                                              Icons.warning_rounded,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                          );
                                        } catch (e) {
                                          print('ERROR on individual chip: $e');
                                          return Chip(
                                            backgroundColor:
                                                Colors.red.shade900,
                                            label: Text(
                                              'Error: $e',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        }
                                      }).toList(),
                                    );
                                  } catch (e) {
                                    print('ERROR on Wrap widget: $e');
                                    return Text(
                                      'Error displaying infected sources: $e',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Graph
              Card(
                color: AppTheme.cardDark,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prediction Results',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Comparing predicted vs. actual traffic types',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY * 1.2, // Add 20% padding on top
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor:
                                    AppTheme.backgroundDark.withOpacity(0.8),
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  String category = group.x == 0
                                      ? 'Normal Traffic'
                                      : 'Bot Traffic';
                                  String source =
                                      rodIndex == 0 ? 'Predicted' : 'Actual';
                                  return BarTooltipItem(
                                    '$source: ${rod.toY.toInt()}\n$category',
                                    const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        value == 0
                                            ? 'Normal Traffic'
                                            : 'Bot Traffic',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxY / 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.white.withOpacity(0.1),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            barGroups: [
                              // Normal Traffic (0)
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: normalPredicted.toDouble(),
                                    color: AppTheme.primaryColor,
                                    width: hasActualCounts ? 13 : 22,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  if (hasActualCounts)
                                    BarChartRodData(
                                      toY: normalActual.toDouble(),
                                      color: AppTheme.secondaryColor,
                                      width: 13,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                ],
                              ),
                              // Bot Traffic (1)
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: botPredicted.toDouble(),
                                    color: AppTheme.accentColor,
                                    width: hasActualCounts ? 13 : 22,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  if (hasActualCounts)
                                    BarChartRodData(
                                      toY: botActual.toDouble(),
                                      color: AppTheme.secondaryColor
                                          .withOpacity(0.7),
                                      width: 13,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(
                              context, 'Predicted', AppTheme.primaryColor),
                          const SizedBox(width: 24),
                          if (hasActualCounts)
                            _buildLegendItem(
                                context, 'Actual', AppTheme.secondaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detailed statistics
              Card(
                color: AppTheme.cardDark,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detailed Statistics',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Prediction summary
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                                context,
                                'Normal Traffic',
                                '$normalPredicted',
                                '${(normalPredicted / totalPredicted * 100).toStringAsFixed(1)}%',
                                AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                                context,
                                'Bot Traffic',
                                '$botPredicted',
                                '${(botPredicted / totalPredicted * 100).toStringAsFixed(1)}%',
                                AppTheme.accentColor),
                          ),
                        ],
                      ),

                      if (hasActualCounts) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'Actual Distribution',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                  context,
                                  'Normal Traffic',
                                  '$normalActual',
                                  '${(normalActual / totalActual * 100).toStringAsFixed(1)}%',
                                  AppTheme.secondaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                  context,
                                  'Bot Traffic',
                                  '$botActual',
                                  '${(botActual / totalActual * 100).toStringAsFixed(1)}%',
                                  AppTheme.secondaryColor.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),

                      // Performance metrics
                      if (result['accuracy'] != null) ...[
                        Text(
                          'Performance Metrics',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                  context,
                                  'Accuracy',
                                  '${(result['accuracy'] * 100).toStringAsFixed(2)}%',
                                  _getAccuracyDescription(result['accuracy']),
                                  _getAccuracyColor(result['accuracy'])),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Infected IPs table
                      if (infectedIps.isNotEmpty) ...[
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'Infected IP Addresses',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundDark.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.3),
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                AppTheme.accentColor.withOpacity(0.1),
                              ),
                              columnSpacing: 40,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Source IP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Destination IP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: List.generate(
                                infectedIps.length > 100
                                    ? 100 // Limit to 100 IPs to prevent performance issues
                                    : infectedIps.length,
                                (index) => DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        infectedIps[index]['src'] ?? 'N/A',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        infectedIps[index]['dst'] ?? 'N/A',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (infectedIps.length > 100)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Showing 100 of ${infectedIps.length} infected IPs',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],

                      const SizedBox(height: 16),

                      // Return to selection button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Back to Selection',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
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
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.9) {
      return Colors.green;
    } else if (accuracy >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getAccuracyDescription(double accuracy) {
    if (accuracy >= 0.9) {
      return 'Excellent';
    } else if (accuracy >= 0.8) {
      return 'Very Good';
    } else if (accuracy >= 0.7) {
      return 'Good';
    } else if (accuracy >= 0.6) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }
}
