// lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  @override
  void initState() {
    super.initState();
    _scanController.initDatabase().then((_) {
      _updateCount();
    });
    _focusNode.requestFocus(); // Foco automático en el input
  }

  // Insertar el código en la base de datos y actualizar el contador
  Future<void> _handleSubmit() async {
    String code = _controller.text;

    // Validar longitud del código
    if (code.length < 7) {
      Fluttertoast.showToast(
        msg: "El código debe tener al menos 7 caracteres.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    } else if (code.length > 15) {
      Fluttertoast.showToast(
        msg: "El código no puede exceder los 15 caracteres.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    // Insertar el código en la base de datos si pasa la validación
    if (code.isNotEmpty) {
      Scan scan = Scan(
        code: code,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      );
      await _scanController.insertScan(scan);
      _controller.clear();
      _focusNode.requestFocus(); // Mantener el enfoque en el input
      _updateCount();
    }
  }

  // Actualiza el contador de scans activos
  Future<void> _updateCount() async {
    int count = await _scanController.getActiveScansCount();
    setState(() {
      _count = count;
    });
  }

  // Mostrar los scans activos en la tabla
  Widget _buildScannedTable() {
    return FutureBuilder<List<Scan>>(
      future: _scanController.getActiveScans(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return Center(child: Text('No scanned items'));
        }
        return DataTable(
          columns: [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Status')),
          ],
          rows: snapshot.data!.map((scan) {
            return DataRow(
              cells: [
                DataCell(Text(scan.id.toString())),
                DataCell(Text(scan.code)),
                DataCell(Text('Scanned')),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input con FocusNode
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _handleSubmit(),
              decoration: InputDecoration(
                labelText: 'Enter barcode',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Botón de carga
            ElevatedButton.icon(
              onPressed: () {
                Fluttertoast.showToast(msg: "Hello, World!");
              },
              icon: Icon(Icons.cloud_sync_outlined),
              label: Text('Upload Scanned Data'),
            ),
            SizedBox(height: 16),
            // Contador de scans activos
            Text('Scanned Items: $_count'),
            SizedBox(height: 16),
            // Tabla de scans activos
            Expanded(child: _buildScannedTable()),
          ],
        ),
      ),
    );
  }
}
