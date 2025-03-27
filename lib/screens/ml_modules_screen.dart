import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import 'comparison_graph_screen.dart';

class MLModulesScreen extends StatefulWidget {
  final String dataset;

  const MLModulesScreen({Key? key, required this.dataset}) : super(key: key);

  @override
  _MLModulesScreenState createState() => _MLModulesScreenState();
}

class _MLModulesScreenState extends State<MLModulesScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  String? _selectedAlgorithm;
  bool _isProcessing = false;
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  String _consoleOutput = '';
  final ScrollController _consoleScrollController = ScrollController();

  final List<Map<String, dynamic>> _algorithms = [
    {
      'name': 'Random Forest',
      'key': 'random_forest',
      'description': 'Ensemble learning method for classification',
      'icon': Icons.forest,
      'color': Colors.green,
    },
    {
      'name': 'XGBoost',
      'key': 'xgboost',
      'description': 'Gradient boosting framework',
      'icon': Icons.speed,
      'color': Colors.blue,
    },
    {
      'name': 'SVM',
      'key': 'svm',
      'description': 'Support Vector Machine classifier',
      'icon': Icons.linear_scale,
      'color': Colors.purple,
    },
    {
      'name': 'KNN',
      'key': 'knn',
      'description': 'K-Nearest Neighbors algorithm',
      'icon': Icons.account_tree,
      'color': Colors.orange,
    },
    {
      'name': 'Logistic Regression',
      'key': 'logistic_regression',
      'description': 'Statistical model for classification',
      'icon': Icons.trending_up,
      'color': Colors.teal,
    },
  ];

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
    _consoleScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;

          // For non-web platforms, we also store the file
          if (!kIsWeb && file.path != null) {
            _selectedFile = File(file.path!);
          } else {
            _selectedFile = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _applyAlgorithm() async {
    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    if (_selectedAlgorithm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an algorithm first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _consoleOutput = '';
    });

    try {
      // For web, we need specialized handling
      if (kIsWeb) {
        _appendToConsole(
            "Web platform detected. Using server-side processing...");
        // For web implementation, you'd typically send the file to a server
        // Here we'll implement a minimal version that shows the real limitations
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Web platform cannot directly use Python models. For accurate predictions, please use the desktop version.'),
            duration: Duration(seconds: 5),
          ),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      } else {
        // For non-web, create a temporary file if needed
        File fileToProcess;
        if (_selectedFile != null) {
          fileToProcess = _selectedFile!;
        } else {
          // Create a temporary file from bytes
          final tempDir = await getTemporaryDirectory();
          fileToProcess =
              File('${tempDir.path}/${_selectedFileName ?? "temp.csv"}');
          await fileToProcess.writeAsBytes(_selectedFileBytes!);
        }

        // Select the appropriate Python script based on the dataset
        String pythonScript;
        if (widget.dataset == 'CTU-13') {
          pythonScript = 'ctu_predict.py';
        } else if (widget.dataset == 'IOT-23') {
          pythonScript = 'iot_predict.py';
        } else {
          throw Exception('Unknown dataset: ${widget.dataset}');
        }

        // Get the current directory
        String workingDirectory = Directory.current.path;
        _appendToConsole('Current directory: $workingDirectory');

        // Format the python script path
        // Navigate to the python directory
        String pythonDir = path.join(workingDirectory, 'python');
        String fullScriptPath = path.join(pythonDir, pythonScript);

        _appendToConsole('Python directory: $pythonDir');
        _appendToConsole('Script path: $fullScriptPath');
        _appendToConsole(
            'Running: python $fullScriptPath with ${fileToProcess.path} and $_selectedAlgorithm');

        try {
          // Run Python script for prediction with the selected algorithm
          final process = await Process.start('python', [
            fullScriptPath,
            fileToProcess.path,
            _selectedAlgorithm!,
          ]);

          // Capture stdout
          process.stdout.transform(utf8.decoder).listen((data) {
            _appendToConsole(data);
          });

          // Capture stderr
          process.stderr.transform(utf8.decoder).listen((data) {
            _appendToConsole("ERROR: $data");
          });

          // Wait for the process to complete
          final exitCode = await process.exitCode;
          _appendToConsole('Process exited with code $exitCode');

          if (exitCode != 0) {
            throw Exception('Prediction failed with exit code $exitCode');
          }

          // Get the last line which should be the JSON result
          final lines = _consoleOutput.split('\n');
          String jsonLine = '';

          // Find the last line that looks like valid JSON (starts with '{')
          for (int i = lines.length - 1; i >= 0; i--) {
            final line = lines[i].trim();
            if (line.startsWith('{') && line.endsWith('}')) {
              jsonLine = line;
              break;
            }
          }

          if (jsonLine.isEmpty) {
            throw Exception('Could not find JSON output in results');
          }

          Map<String, dynamic> results;
          try {
            results = json.decode(jsonLine);
          } catch (e) {
            _appendToConsole('Failed to parse JSON: $jsonLine');
            throw Exception('Failed to parse prediction results: $e');
          }

          if (!mounted) return;

          // Create a map with the selected algorithm as key
          final formattedResults = {_selectedAlgorithm!: results};

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComparisonGraphScreen(
                predictionResults: formattedResults,
                dataset: widget.dataset,
              ),
            ),
          );
        } catch (e) {
          _appendToConsole('Exception caught: $e');
          throw e;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during prediction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _appendToConsole(String text) {
    setState(() {
      _consoleOutput += text;
    });

    // Schedule a scroll to the bottom after the state has been updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.animateTo(
          _consoleScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('${widget.dataset} ML Modules'),
        backgroundColor: AppTheme.cardDark,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Card(
                      color: AppTheme.cardDark,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 64,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${widget.dataset} Bot Detection',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select a CSV file and an algorithm to analyze the data',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // File selection section
                            Text(
                              'Data File',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _isProcessing ? null : _pickFile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.3),
                                  ),
                                  color: AppTheme.backgroundDark,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.upload_file,
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
                                            _selectedFileName != null
                                                ? _selectedFileName!
                                                : 'No file selected',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                ),
                                          ),
                                          Text(
                                            'Click to select CSV file',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.white70,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Algorithm Selection Section
                            Text(
                              'Select Algorithm',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            ..._algorithms.map(
                                (algorithm) => _buildAlgorithmTile(algorithm)),

                            const SizedBox(height: 32),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: (_isProcessing ||
                                        _selectedFileName == null ||
                                        _selectedAlgorithm == null)
                                    ? null
                                    : _applyAlgorithm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isProcessing
                                    ? const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.play_arrow),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Run Analysis',
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
                            ),
                            if (kIsWeb)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  'Note: Web platform cannot directly use Python models. For accurate predictions, please use the desktop version.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.red.shade300,
                                        fontStyle: FontStyle.italic,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            // Console Output
                            if (!kIsWeb && _consoleOutput.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Console Output',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: SingleChildScrollView(
                                  controller: _consoleScrollController,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _consoleOutput,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          color: Colors.greenAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildAlgorithmTile(Map<String, dynamic> algorithm) {
    final bool isSelected = _selectedAlgorithm == algorithm['key'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: _isProcessing
            ? null
            : () {
                setState(() {
                  _selectedAlgorithm = algorithm['key'];
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (algorithm['color'] as Color)
                  : AppTheme.primaryColor.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? (algorithm['color'] as Color).withOpacity(0.1)
                : AppTheme.backgroundDark,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (algorithm['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  algorithm['icon'] as IconData,
                  color: algorithm['color'] as Color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      algorithm['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                    ),
                    Text(
                      algorithm['description'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: algorithm['color'] as Color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
