import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/rendering.dart';

// --- 🌑 DARK MODE THEME COLORS ---
class AppColors {
  static const primary = Colors.white;
  static const secondary = Color(0xFF94A3B8);
  static const accent = Color(0xFF3B82F6);
  static const background = Color(0xFF020617);
  static const surface = Color(0xFF0F172A);
  static const border = Color(0xFF1E293B);
}

// TODO: Replace with your actual API key
const String _apiKey = 'AIzaSyDgeHrT5bRyRXGI_wMqFRspzSgsH4GSOmU';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 SYSTEM UI CONFIGURATION
  // Use edgeToEdge to allow the app to draw behind the system bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KABI22 PDF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          background: AppColors.background,
          surface: AppColors.surface,
          secondary: AppColors.accent,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// --- 🏠 HOME SCREEN ---
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result?.files.single.path != null) {
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(path: result!.files.single.path!, title: result.files.single.name)));
      }
    } catch (e) { print(e); }
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -100,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withOpacity(0.2))
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 5 * math.sin(_controller.value * 2 * math.pi)),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 10))],
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppColors.accent),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text("KABI22 PDF", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text("Smart. Fast. Intelligent.", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.secondary)),
                const SizedBox(height: 48),
                InkWell(
                  onTap: _isLoading ? null : _pickPdfFile,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_rounded, color: Colors.white), SizedBox(width: 8), Text("Open Document", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 📄 NATIVE PDF VIEWER ---
class PdfViewerScreen extends StatefulWidget {
  final String path;
  final String title;
  const PdfViewerScreen({Key? key, required this.path, required this.title}) : super(key: key);
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

enum DraggingMode { none, createNew, moveSelection, resizeTL, resizeTR, resizeBL, resizeBR }

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();
  final GlobalKey _globalKey = GlobalKey();

  int _currentPage = 0;
  int _totalPages = 0;
  bool _uiVisible = true;
  bool _isSnippingMode = false;

  Rect? _selectionRect;
  DraggingMode _draggingMode = DraggingMode.none;
  Offset? _dragStartOffset;
  Offset? _initialRectTopLeftWhenDragging;
  final double _handleTouchSize = 40.0;

  DateTime? _pointerDownTime;
  Offset? _pointerDownPosition;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _onScrollbarDrag(double percentage) async {
    if (_totalPages == 0) return;
    int targetPage = (percentage * _totalPages).round().clamp(0, _totalPages - 1);
    final controller = await _controller.future;
    controller.setPage(targetPage);
  }

  Future<void> _captureScreenAndCrop() async {
    if (_selectionRect == null || _selectionRect!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an area first")));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accent)));

    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image screenImage = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await screenImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      img.Image? fullImage = img.decodePng(pngBytes);

      if (fullImage != null) {
        double scale = 2.0;

        int cropX = (_selectionRect!.left * scale).toInt().clamp(0, fullImage.width);
        int cropY = (_selectionRect!.top * scale).toInt().clamp(0, fullImage.height);
        int cropW = (_selectionRect!.width * scale).toInt().clamp(1, fullImage.width - cropX);
        int cropH = (_selectionRect!.height * scale).toInt().clamp(1, fullImage.height - cropY);

        img.Image croppedImage = img.copyCrop(fullImage, x: cropX, y: cropY, width: cropW, height: cropH);

        final tempDir = await getTemporaryDirectory();
        final File file = File('${tempDir.path}/screen_crop.jpg');
        await file.writeAsBytes(img.encodeJpg(croppedImage));

        await _performOcr(file);
      }
    } catch (e) {
      print("Error capturing screen: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _performOcr(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFile(imageFile));
      if (mounted) {
        Navigator.pop(context);
        _showResultDialog(recognizedText.text);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("OCR Error: $e");
    } finally {
      textRecognizer.close();
    }
  }

  void _showResultDialog(String text) {
    setState(() {
      _isSnippingMode = false;
      _selectionRect = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black)],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Extracted Text", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.copy, color: AppColors.secondary), onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                      }),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(extractedText: text)));
                        },
                        child: const Icon(Icons.smart_toy_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: SelectableText(text, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)))),
          ],
        ),
      ),
    );
  }

  bool _isPointNear(Offset point, Offset target) => (point - target).distance <= _handleTouchSize;

  DraggingMode _determineDraggingMode(Offset touchPoint) {
    if (_selectionRect == null) return DraggingMode.createNew;
    if (_isPointNear(touchPoint, _selectionRect!.topLeft)) return DraggingMode.resizeTL;
    if (_isPointNear(touchPoint, _selectionRect!.topRight)) return DraggingMode.resizeTR;
    if (_isPointNear(touchPoint, _selectionRect!.bottomLeft)) return DraggingMode.resizeBL;
    if (_isPointNear(touchPoint, _selectionRect!.bottomRight)) return DraggingMode.resizeBR;
    if (_selectionRect!.contains(touchPoint)) return DraggingMode.moveSelection;
    return DraggingMode.createNew;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // 🛑 Ensure content draws behind bars
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(
          children: [
            // 1. NATIVE PDF VIEWER (Full Screen - No Padding)
            Listener(
              onPointerDown: (event) {
                _pointerDownTime = DateTime.now();
                _pointerDownPosition = event.position;
              },
              onPointerUp: (event) {
                if (_pointerDownTime == null || _pointerDownPosition == null) return;
                final duration = DateTime.now().difference(_pointerDownTime!).inMilliseconds;
                final distance = (event.position - _pointerDownPosition!).distance;

                if (duration < 300 && distance < 10) {
                  if (!_isSnippingMode) {
                    setState(() {
                      _uiVisible = !_uiVisible;
                    });
                  }
                }
                _pointerDownTime = null;
                _pointerDownPosition = null;
              },
              child: PDFView(
                filePath: widget.path,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: false,
                pageSnap: false,
                fitPolicy: FitPolicy.WIDTH,
                nightMode: false,
                onRender: (pages) => setState(() => _totalPages = pages ?? 0),
                onViewCreated: (controller) => _controller.complete(controller),
                onPageChanged: (page, total) => setState(() => _currentPage = page ?? 0),
                onError: (error) => print(error.toString()),
              ),
            ),

            // 2. SNIP OVERLAY
            if (_isSnippingMode)
              Positioned.fill(
                child: GestureDetector(
                  onPanDown: (details) {
                    setState(() {
                      _dragStartOffset = details.localPosition;
                      _draggingMode = _determineDraggingMode(_dragStartOffset!);
                      if (_draggingMode == DraggingMode.createNew) {
                        _selectionRect = Rect.fromPoints(_dragStartOffset!, _dragStartOffset!);
                      } else if (_draggingMode == DraggingMode.moveSelection) {
                        _initialRectTopLeftWhenDragging = _selectionRect!.topLeft;
                      }
                    });
                  },
                  onPanUpdate: (details) {
                    if (_dragStartOffset == null) return;
                    setState(() {
                      final currentPoint = details.localPosition;
                      switch (_draggingMode) {
                        case DraggingMode.createNew: _selectionRect = Rect.fromPoints(_dragStartOffset!, currentPoint); break;
                        case DraggingMode.moveSelection:
                          if (_initialRectTopLeftWhenDragging != null) {
                            _selectionRect = _selectionRect!.shift(currentPoint - _dragStartOffset!);
                            _dragStartOffset = currentPoint;
                          }
                          break;
                        case DraggingMode.resizeTL: _selectionRect = Rect.fromLTRB(currentPoint.dx, currentPoint.dy, _selectionRect!.right, _selectionRect!.bottom); break;
                        case DraggingMode.resizeTR: _selectionRect = Rect.fromLTRB(_selectionRect!.left, currentPoint.dy, currentPoint.dx, _selectionRect!.bottom); break;
                        case DraggingMode.resizeBL: _selectionRect = Rect.fromLTRB(currentPoint.dx, _selectionRect!.top, _selectionRect!.right, currentPoint.dy); break;
                        case DraggingMode.resizeBR: _selectionRect = Rect.fromLTRB(_selectionRect!.left, _selectionRect!.top, currentPoint.dx, currentPoint.dy); break;
                        case DraggingMode.none: break;
                      }
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      if (_selectionRect != null) _selectionRect = Rect.fromPoints(_selectionRect!.topLeft, _selectionRect!.bottomRight);
                      _draggingMode = DraggingMode.none;
                    });
                  },
                  child: CustomPaint(
                    painter: SelectionPainter(rect: _selectionRect),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

            // 3. SIDE SCROLLBAR
            if (_totalPages > 1 && !_isSnippingMode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: _uiVisible ? 0 : -60,
                top: 100, bottom: 100,
                child: CustomVerticalScrollbar(currentPage: _currentPage + 1, totalPages: _totalPages, onDrag: _onScrollbarDrag),
              ),

            // 4. HEADER
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _uiVisible ? 0 : -120,
              left: 0, right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 100,
                    // Manual padding for status bar protection
                    padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.95),
                      border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        _GlassButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isSnippingMode ? "Draw Box to Extract" : widget.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                              if(_isSnippingMode) const Text("Select directly on screen", style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (!_isSnippingMode)
                          _GlassButton(icon: Icons.crop_free_rounded, onTap: () => setState(() => _isSnippingMode = true), active: false),
                        if (_isSnippingMode) ...[
                          _GlassButton(icon: Icons.close_rounded, onTap: () => setState(() { _isSnippingMode = false; _selectionRect = null; }), color: Colors.redAccent),
                          const SizedBox(width: 12),
                          _GlassButton(icon: Icons.check_rounded, onTap: _captureScreenAndCrop, color: AppColors.accent, filled: true),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 5. PAGE INDICATOR (MOVED HIGHER)
            if (_totalPages > 0 && !_isSnippingMode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                // 🔥 UPDATED: Moved up to 80 (was 30)
                bottom: _uiVisible ? 80 : -60,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text("Page ${_currentPage + 1} of $_totalPages", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- 💬 CHAT SCREEN ---
class ChatScreen extends StatefulWidget {
  final String extractedText;
  const ChatScreen({Key? key, required this.extractedText}) : super(key: key);
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAI();
    _textController.text = "what is mean by:\n${widget.extractedText}\n\nexplain briefly";
  }

  void _initAI() {
    _model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: _apiKey);
    _chat = _model.startChat();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    setState(() { _isLoading = true; _messages.add({'role': 'user', 'text': message}); });
    _textController.clear();
    _scrollToBottom();
    try {
      final response = await _chat.sendMessage(Content.text(message));
      setState(() {
        _isLoading = false;
        if (response.text != null) _messages.add({'role': 'model', 'text': response.text!});
      });
      _scrollToBottom();
    } catch (e) {
      setState(() { _isLoading = false; _messages.add({'role': 'model', 'text': 'Error: $e'}); });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AI Assistant"),
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final isUser = _messages[i]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: isUser ? null : Border.all(color: AppColors.border),
                    ),
                    child: isUser
                        ? Text(_messages[i]['text']!, style: const TextStyle(color: Colors.white))
                        : MarkdownBody(data: _messages[i]['text']!, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))),
                  ),
                );
              }
          )),
          if(_isLoading) const LinearProgressIndicator(color: AppColors.accent, backgroundColor: Colors.transparent),

          Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, top: 12, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: TextField(
                      controller: _textController,
                      maxLines: 5, minLines: 1,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Message...",
                        hintStyle: TextStyle(color: AppColors.secondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  child: FloatingActionButton(
                    mini: true,
                    elevation: 0,
                    backgroundColor: AppColors.accent,
                    onPressed: () => _sendMessage(_textController.text),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? color;
  final bool filled;
  const _GlassButton({required this.icon, required this.onTap, this.active = true, this.color, this.filled = false});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: filled ? (color ?? AppColors.primary) : (active ? Colors.white.withOpacity(0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: filled ? Colors.white : (color ?? Colors.white), size: 22),
      ),
    );
  }
}

class CustomVerticalScrollbar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(double) onDrag;
  const CustomVerticalScrollbar({Key? key, required this.currentPage, required this.totalPages, required this.onDrag}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double trackHeight = constraints.maxHeight;
      final double thumbSize = 60.0;
      final double progress = totalPages > 1 ? (currentPage - 1) / (totalPages - 1) : 0.0;
      final double thumbTop = progress * (trackHeight - thumbSize);
      return SizedBox(
        width: 36,
        child: GestureDetector(
          onVerticalDragUpdate: (details) => onDrag((details.localPosition.dy / trackHeight).clamp(0.0, 1.0)),
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              Positioned(
                top: thumbTop, right: 0,
                child: Container(
                  width: 6, height: thumbSize,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class SelectionPainter extends CustomPainter {
  final Rect? rect;
  SelectionPainter({this.rect});
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final rectPath = rect != null ? (Path()..addRect(rect!)) : Path();
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, rectPath);
    canvas.drawPath(overlayPath, Paint()..color = Colors.black.withOpacity(0.6));
    if (rect != null) {
      final borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0;
      canvas.drawRect(rect!, borderPaint);
      final handlePaint = Paint()..color = Colors.white;
      final handleStroke = Paint()..color = AppColors.accent..style = PaintingStyle.stroke..strokeWidth = 2;
      for (var p in [rect!.topLeft, rect!.topRight, rect!.bottomLeft, rect!.bottomRight]) {
        canvas.drawCircle(p, 8, handlePaint);
        canvas.drawCircle(p, 8, handleStroke);
      }
    }
  }
  @override
  bool shouldRepaint(covariant SelectionPainter old) => old.rect != rect;
}