// lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../controllers/scan_controller.dart';
import '../models/scan_model.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();
  int _count = 0;
  bool _isUploading = false; // Indicates if the upload process is running

  @override
  void initState() {
    super.initState();
    _scanController.initDatabase().then((_) {
      _updateCount();
    });
    _focusNode.requestFocus(); // Automatic focus on the input
  }

  // Insert the code into the database and update the count
  Future<void> _handleSubmit() async {
    String code = _controller.text;

    // Validate code length
    if (code.length < 7) {
      Fluttertoast.showToast(
        msg: "The code must be at least 7 characters long.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    } else if (code.length > 15) {
      Fluttertoast.showToast(
        msg: "The code cannot exceed 15 characters.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    // Check for duplicates before inserting
    if (await _scanController.scanExists(code)) {
      Fluttertoast.showToast(
        msg: "This code is already registered.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    // Insert the code into the database if it passes validation
    if (code.isNotEmpty) {
      Scan scan = Scan(
        code: code,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      );
      await _scanController.insertScan(scan);
      _controller.clear();
      _focusNode.requestFocus(); // Keep focus on the input
      _updateCount();
    }
  }

  // Update the count of active scans
  Future<void> _updateCount() async {
    int count = await _scanController.getActiveScansCount();
    setState(() {
      _count = count;
    });
  }

  // Method to upload scanned data to the API
  Future<void> _uploadScannedData() async {
    setState(() {
      _isUploading = true; // Start showing the progress bar
    });

    List<Scan> scans = await _scanController.getActiveScans();

    for (Scan scan in scans) {
      final response = await http.post(
        Uri.parse(
            'http://192.168.130.9:8086/index.php/api/receive-raw-material'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'code': scan.code,
          'updated_at': scan.createdAt,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        // Delete the record from the database
        await _scanController.deleteScan(scan.id!);
        Fluttertoast.showToast(
          msg: "Code sent: ${scan.code}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else if (response.statusCode == 500) {
        Fluttertoast.showToast(
          msg: "Error connecting to the server.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }

    // Update the count after uploading
    _updateCount();

    setState(() {
      _isUploading = false; // Stop showing the progress bar
    });
  }

  // Display active scans in the table
  Widget _buildScannedTable() {
    return FutureBuilder<List<Scan>>(
      future: _scanController.getActiveScans(),
      builder: (context, snapshot) {
        if (_isUploading) {
          // Show the progress bar instead of the table
          return Center(child: LinearProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return Center(child: Text('No scanned items'));
        }
        return DataTable(
          columns: [
            // DataColumn(label: Text('ID')),
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Created At'))
          ],
          rows: snapshot.data!.map((scan) {
            return DataRow(
              cells: [
                // DataCell(Text(scan.id.toString())),
                DataCell(Text(scan.code)),
                DataCell(
                  Text(
                    scan.status == true ? 'Scanned' : 'Loaded',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color:
                            scan.status == true ? Colors.orange : Colors.green),
                  ),
                ),
                DataCell(Text(scan.createdAt)),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RawMaterial Scanning'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (value) => _handleSubmit(),
              decoration: InputDecoration(
                labelText: 'Enter scan code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            Text('Total active scans: $_count'),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _uploadScannedData,
              child: Text('Upload Scanned Data'),
            ),
            SizedBox(height: 16.0),
            Expanded(
                child: _buildScannedTable()), // Table or Progress Indicator
          ],
        ),
      ),
    );
  }
}
