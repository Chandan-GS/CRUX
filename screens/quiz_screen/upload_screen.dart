import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:quiz_app/screens/quiz_screen/quiz_input_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool isTappedPdf = false;
  bool isTappedCamera = false;
  bool pdfLoaded = false;
  File? file;

  bool _isProcessing = false;

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    debugPrint("file picked");

    if (result != null) {
      file = File(result.files.single.path!);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizInput(file: file!, isPDF: true),
          ),
        );
      }
    }
  }

  void onTapColorChangePdf() {
    setState(() {
      isTappedPdf = true;
    });
  }

  void onTapColorChangeCamera() {
    setState(() {
      isTappedCamera = true;
    });
  }

  Future<String> _processScannedImages(List<String> imagePaths) async {
    final textRecognizer = TextRecognizer();
    String allExtractedText = "";

    try {
      for (String path in imagePaths) {
        final file = File(path);
        final inputImage = InputImage.fromFile(file);
        final RecognizedText recognizedText = await textRecognizer.processImage(
          inputImage,
        );
        allExtractedText += "${recognizedText.text}\n\n";
      }
    } catch (e) {
      debugPrint("Error during text recognition: $e");
    } finally {
      textRecognizer.close();
    }
    return allExtractedText;
  }

  Future<void> scanDocument() async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create document scanner with proper options
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: 5,
        isGalleryImport: true,
      );

      final documentScanner = DocumentScanner(options: options);

      // Start scanning
      final result = await documentScanner.scanDocument();

      // Close the scanner
      documentScanner.close();

      if (!mounted) return;

      // Check if we have images
      if (result.images.isNotEmpty) {
        debugPrint("Scanned ${result.images.length} images");

        // Process OCR on scanned images
        String extractedText = await _processScannedImages(result.images);

        setState(() {
          _isProcessing = false;
        });

        if (!mounted) return;

        if (extractedText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No text found in the scanned document."),
            ),
          );
        } else {
          // Navigate to QuizInput with extracted text
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuizInput(content: extractedText, file: null, isPDF: false),
            ),
          );
        }
      } else {
        // User cancelled or no images scanned
        setState(() {
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scanning was cancelled.")),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      debugPrint("Error scanning document: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error during scanning: ${e.toString()}"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Extracting text from images..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  onTapColorChangePdf();
                  pickFile();
                },
                child: DottedBorder(
                  options: RectDottedBorderOptions(
                    color: Theme.of(context).colorScheme.secondary,
                    borderPadding: const EdgeInsets.fromLTRB(30, 25, 30, 20),
                    strokeWidth: 4,
                    dashPattern: pdfLoaded ? [8, 0] : [8, 8],
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 7, 12, 2),
                    color: isTappedPdf
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  onTapColorChangeCamera();
                  scanDocument();
                },
                child: DottedBorder(
                  options: RectDottedBorderOptions(
                    color: Theme.of(context).colorScheme.secondary,
                    borderPadding: const EdgeInsets.fromLTRB(30, 25, 30, 20),
                    strokeWidth: 4,
                    dashPattern: pdfLoaded ? [8, 0] : [8, 8],
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 7, 12, 2),
                    color: isTappedCamera
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
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
