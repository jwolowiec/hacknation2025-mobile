import 'dart:convert';
import 'dart:io'; // <--- 1. WYMAGANE DO IGNOROWANIA BŁĘDÓW SSL
import 'package:flutter/material.dart';
import 'package:hacknation2025mobile/theme/theme.dart';
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
        primarySwatch: AppTheme.colors.primary,
        scaffoldBackgroundColor: AppTheme.colors.appBackground,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: AppTheme.colors.appBackground,
          iconTheme: IconThemeData(
            color: AppTheme.colors.textPrimary,
          ),
          actionsIconTheme: IconThemeData(
            color: AppTheme.colors.textPrimary,
          ),
        ),
        textTheme: AppTheme.typography,
        inputDecorationTheme: InputDecorationTheme(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(AppTheme.mainBorderRadiusValue)),
          ),
          fillColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppTheme.colors.primary,
        ),
        outlinedButtonTheme: const OutlinedButtonThemeData(
            style: ButtonStyle(
          shape: MaterialStatePropertyAll(StadiumBorder()),
        )),
        elevatedButtonTheme: const ElevatedButtonThemeData(
            style: ButtonStyle(
          elevation: MaterialStatePropertyAll(0),
          shape: MaterialStatePropertyAll(StadiumBorder()),
        )),
        filledButtonTheme: const FilledButtonThemeData(
            style: ButtonStyle(
          padding: MaterialStatePropertyAll(
              EdgeInsets.symmetric(vertical: 18, horizontal: 24)),
          elevation: MaterialStatePropertyAll(0),
          shape: MaterialStatePropertyAll(StadiumBorder()),
        )),
        textButtonTheme: const TextButtonThemeData(
            style: ButtonStyle(
          padding: MaterialStatePropertyAll(
              EdgeInsets.symmetric(vertical: 18, horizontal: 24)),
          elevation: MaterialStatePropertyAll(0),
          shape: MaterialStatePropertyAll(StadiumBorder()),
        )),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.colors.appBackground,
          elevation: 0,
          selectedItemColor: AppTheme.colors.primary.shade500,
          unselectedItemColor: const Color(0xff4b5563),
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppTheme.mainBorderRadiusValue * 2)),
          titleTextStyle: AppTheme.typography.headlineMedium,
          contentTextStyle: AppTheme.typography.bodyMedium,
        ),
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

      final url = Uri.parse('$_serverHost/websites/$uuid/verify-token');

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
            _statusColor = Colors.red;
          }
        });
      } else {
        setState(() {
          _statusMessage = 'BŁĄD SERWERA (${response.statusCode})';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      // TODO: handle
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
