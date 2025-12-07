import 'dart:convert';
import 'dart:io'; // <--- 1. WYMAGANE DO IGNOROWANIA BŁĘDÓW SSL
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

// --- 2. KLASA, KTÓRA MÓWI "UFAJ WSZYSTKIEMU" ---
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // --- 3. AKTYWACJA IGNOROWANIA CERTYFIKATÓW ---
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QRScannerPage(),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with WidgetsBindingObserver {
  // Adres serwera
  final String _serverHost = 'https://prawdawsieci.pl';

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isProcessing = false;
  bool _scanFinished = false;

  String _statusMessage = 'Zeskanuj kod QR';
  Color _statusColor = Colors.black87;
  String _debugInfo = '';

  // Dane z JSONa
  String? _institutionName;
  bool? _isValid;

  Future<void> _processQrCode(String rawQrValue) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _scanFinished = false;
      _statusMessage = 'Przetwarzanie...';
      _statusColor = Colors.blue;
      _debugInfo = 'Raw: $rawQrValue';
      _institutionName = null;
      _isValid = null;
    });

    await controller.stop();

    try {
      final cleanCode = rawQrValue.trim();
      String uuid = '';
      String token = '';

      if (cleanCode.contains('/')) {
        final sanitized = cleanCode.endsWith('/')
            ? cleanCode.substring(0, cleanCode.length - 1)
            : cleanCode;

        final parts = sanitized.split('/');

        if (parts.length >= 2) {
          token = parts.last;
          uuid = parts[parts.length - 2];
        } else {
          throw Exception("Za mało segmentów w kodzie.");
        }
      } else {
        throw Exception("Brak znaków '/' w kodzie.");
      }

      setState(() {
        _debugInfo += '\nUUID: $uuid\nToken: $token';
      });

      final url = Uri.parse('$_serverHost/websites/$uuid/verify-token');

      // Pokazujemy URL w logach
      setState(() {
        _debugInfo += '\nRequest URL: $url';
      });

      // --- LOGOWANIE WYSYŁANIA ---
      debugPrint('========================================');
      debugPrint('🚀 WYSYŁAM ZAPYTANIE POST');
      debugPrint('🔗 URL: $url');
      debugPrint('📦 BODY: ${jsonEncode({'token': token})}');
      debugPrint('========================================');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-dupa': 'blada',
        },
        body: jsonEncode({
          'token': token,
        }),
      );

      // --- LOGOWANIE ODPOWIEDZI ---
      debugPrint('========================================');
      debugPrint('✅ OTRZYMANO ODPOWIEDŹ');
      debugPrint('🔢 STATUS CODE: ${response.statusCode}');
      debugPrint('📄 RESPONSE BODY:\n${response.body}');
      debugPrint('========================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Dekodujemy body jako UTF-8
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);

        setState(() {
          _isValid = data['valid'];
          _institutionName = data['name'];

          if (_isValid == true) {
            _statusMessage = 'Weryfikacja pomyślna!';
            _statusColor = Colors.green;
          } else {
            _statusMessage = 'Weryfikacja negatywna!';
            _statusColor = Colors.orange;
          }

          _debugInfo +=
              '\nOdpowiedź serwera:\n${const JsonEncoder.withIndent('  ').convert(data)}';
        });
      } else {
        setState(() {
          _statusMessage = 'BŁĄD SERWERA (${response.statusCode})';
          _statusColor = Colors.red;
          _debugInfo += '\nBody: ${response.body}';
        });
      }
    } catch (e) {
      // --- LOGOWANIE BŁĘDU ---
      debugPrint('========================================');
      debugPrint('❌ WYSTĄPIŁ WYJĄTEK (EXCEPTION)');
      debugPrint(e.toString());
      debugPrint('========================================');

      setState(() {
        _statusMessage = 'BŁĄD POŁĄCZENIA';
        _statusColor = Colors.red;
        _debugInfo += '\nSzczegóły błędu:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _scanFinished = true;
        });
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
      _scanFinished = false;
      _statusMessage = 'Zeskanuj kod QR';
      _statusColor = Colors.black87;
      _debugInfo = '';
      _institutionName = null;
      _isValid = null;
    });
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weryfikator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetScanner,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: _scanFinished
                ? Container(
                    color: _statusColor.withOpacity(0.1),
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isValid == true ? Icons.check_circle : Icons.error,
                          size: 80,
                          color: _statusColor,
                        ),
                        const SizedBox(height: 20),
                        if (_institutionName != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              _institutionName!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _resetScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text("SKANUJ PONOWNIE"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                        )
                      ],
                    ),
                  )
                : _isProcessing
                    ? Container(
                        color: Colors.black,
                        child: const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white)),
                      )
                    : MobileScanner(
                        controller: controller,
                        onDetect: (BarcodeCapture capture) {
                          if (_isProcessing || _scanFinished) return;

                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              _processQrCode(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[100],
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _statusColor,
                      ),
                    ),
                    const Divider(),
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("LOGI (Debug):",
                            style:
                                TextStyle(fontSize: 10, color: Colors.grey))),
                    Text(
                      _debugInfo,
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}
