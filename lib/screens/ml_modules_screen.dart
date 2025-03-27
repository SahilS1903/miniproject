import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../theme/app_theme.dart';

class MLModulesScreen extends StatefulWidget {
  final String dataset;

  const MLModulesScreen({Key? key, required this.dataset}) : super(key: key);

  @override
  _MLModulesScreenState createState() => _MLModulesScreenState();
}

class _MLModulesScreenState extends State<MLModulesScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  bool _isProcessing = false;
  List<List<String>>? _csvData;
  String? _selectedModel;
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        // Parse CSV data
        final csvString = String.fromCharCodes(fileBytes);
        final rows = csvString.split('\n');
        if (rows.isEmpty) {
          _showError('CSV file is empty');
          return;
        }

        // Parse CSV rows into list of columns
        final parsedData = rows.map((row) => row.split(',')).toList();

        setState(() {
          _selectedFile = File(fileName);
          _csvData = parsedData;
          _selectedModel = null;
        });
      }
    } catch (e) {
      _showError('Error reading file: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _applyModel() async {
    if (_selectedFile == null || _selectedModel == null) {
      _showError('Please select both a file and a model');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // TODO: Implement actual model processing
      await Future.delayed(const Duration(seconds: 2));
      _showSuccess('Successfully processed with $_selectedModel');
    } catch (e) {
      _showError('Error processing file: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.backgroundDark.withBlue(30),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: Text('ML Modules - ${widget.dataset}'),
                actions: [
                  if (_selectedModel != null &&
                      _selectedFile != null &&
                      !_isProcessing)
                    TextButton.icon(
                      onPressed: _applyModel,
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Apply $_selectedModel'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.successColor,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('About ML Modules'),
                          content: const Text(
                            'Select a CSV file to preview its contents, then choose an ML model to analyze the data. The model will process the data and provide detection results.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // File Selection Section
                              Text(
                                'Dataset File',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: InkWell(
                                  onTap: _isProcessing ? null : _pickFile,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.cardDark,
                                          AppTheme.cardDark.withOpacity(0.8),
                                        ],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.upload_file,
                                              size: 24,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedFile == null
                                                      ? 'Select CSV File'
                                                      : path.basename(
                                                          _selectedFile!.path),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _selectedFile == null
                                                      ? 'Tap to choose a file'
                                                      : 'Tap to change file',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!_isProcessing)
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_csvData != null) ...[
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'File Preview',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.cardDark,
                                        AppTheme.cardDark.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: _csvData!.first
                                          .map((header) => DataColumn(
                                                label: Text(
                                                  header,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge,
                                                ),
                                              ))
                                          .toList(),
                                      rows: _csvData!
                                          .skip(1)
                                          .take(5)
                                          .map((row) => DataRow(
                                                cells: row
                                                    .map((cell) =>
                                                        DataCell(Text(cell)))
                                                    .toList(),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                                if (_csvData!.length > 6)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Showing first 5 rows of ${_csvData!.length - 1} total rows',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // ML Modules Section
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Model',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.2,
                                children: [
                                  _buildMLModuleCard(
                                    'Random Forest',
                                    'Ensemble learning method for classification',
                                    Icons.forest,
                                    'Random Forest',
                                    [
                                      AppTheme.primaryColor,
                                      AppTheme.secondaryColor
                                    ],
                                  ),
                                  _buildMLModuleCard(
                                    'XGBoost',
                                    'Gradient boosting framework',
                                    Icons.speed,
                                    'XGBoost',
                                    [
                                      AppTheme.secondaryColor,
                                      AppTheme.accentColor
                                    ],
                                  ),
                                  _buildMLModuleCard(
                                    'SVM',
                                    'Support Vector Machine classifier',
                                    Icons.linear_scale,
                                    'SVM',
                                    [
                                      AppTheme.accentColor,
                                      AppTheme.primaryColor
                                    ],
                                  ),
                                  _buildMLModuleCard(
                                    'KNN',
                                    'K-Nearest Neighbors algorithm',
                                    Icons.account_tree,
                                    'KNN',
                                    [
                                      AppTheme.primaryColor,
                                      AppTheme.accentColor
                                    ],
                                  ),
                                  _buildMLModuleCard(
                                    'Logistic Regression',
                                    'Statistical model for classification',
                                    Icons.trending_up,
                                    'Logistic Regression',
                                    [
                                      AppTheme.secondaryColor,
                                      AppTheme.primaryColor
                                    ],
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildMLModuleCard(
    String title,
    String description,
    IconData icon,
    String modelName,
    List<Color> gradientColors,
  ) {
    final isSelected = _selectedModel == modelName;
    final isEnabled = _selectedFile != null && !_isProcessing;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: isSelected ? 16 : 8,
          shadowColor: isSelected ? gradientColors[0].withOpacity(0.4) : null,
          child: InkWell(
            onTap: isEnabled
                ? () {
                    setState(() {
                      _selectedModel = modelName;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isSelected
                        ? gradientColors[0].withOpacity(0.2)
                        : AppTheme.cardDark,
                    isSelected
                        ? gradientColors[1].withOpacity(0.1)
                        : AppTheme.cardDark.withOpacity(0.8),
                  ],
                ),
                border: Border.all(
                  color: isSelected
                      ? gradientColors[0].withOpacity(0.5)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isSelected
                                ? gradientColors[0]
                                : AppTheme.primaryColor)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isSelected
                                  ? gradientColors[0]
                                  : AppTheme.primaryColor)
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isSelected
                            ? gradientColors[0]
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected ? gradientColors[0] : null,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isEnabled
                                ? null
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.5),
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
