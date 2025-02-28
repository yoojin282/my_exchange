import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:my_exchange/constants.dart';
import 'package:my_exchange/widgets/debouncer.dart';
import 'package:translator/translator.dart';

enum _TTSState { playing, stopped }

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _controller = TextEditingController(text: '');
  final _focusNode = FocusNode();
  final _translator = GoogleTranslator();
  late final FlutterTts _tts;
  late final Debouncer _debouncer;

  bool _isSearch = false;
  _TTSState _ttsState = _TTSState.stopped;
  // bool _isKoreanInstalled = true;
  // bool _isEnglishInstalled = true;
  // bool _isThaiInstalled = true;

  String _source = availableLanguage[0];
  List<String> _target =
      availableLanguage
          .where((element) => element != availableLanguage[0])
          .toList();

  String _translated1 = "";
  String _translated2 = "";
  String _searchedText = '';

  @override
  void initState() {
    super.initState();
    _initTTS();
    _debouncer = Debouncer(
      milliseconds: 500,
      action: () {
        if (_controller.text.isEmpty) return;
        _translate(_controller.text);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _initTTS() {
    _tts = FlutterTts();
    _setAwaitOptions();
    if (Platform.isAndroid) {
      _tts.setEngine('com.google.android.tts').then((engine) {
        // Future.wait([
        //   _tts.isLanguageInstalled('ko-KR'),
        //   _tts.isLanguageInstalled('en-US'),
        //   _tts.isLanguageInstalled('th-TH')
        // ]).then(
        //   (value) => setState(() {
        //     _isKoreanInstalled = value[0];
        //     _isEnglishInstalled = value[1];
        //     _isThaiInstalled = value[2];
        //   }),
        // );
        // _tts.getVoices.then((value) => print(value));
      });

      // _getDefaultEngine();
      // _getDefaultVoice();
    }

    // _tts.setStartHandler(() {
    //   setState(() {
    //     _ttsState = _TTSState.playing;
    //   });
    // });
    _tts.setCompletionHandler(() {
      setState(() {
        _ttsState = _TTSState.stopped;
      });
    });
    _tts.setErrorHandler((msg) {
      setState(() {
        logger.e("[TTS] error: $msg");
        _ttsState = _TTSState.stopped;
      });
    });
  }

  Future<void> _setAwaitOptions() async {
    await _tts.awaitSpeakCompletion(true);
  }

  // Future<void> _getDefaultEngine() async {
  //   var engine = await _tts.getDefaultEngine;
  //   if (engine != null) {
  //     print(engine);
  //   }
  // }

  // Future<void> _getDefaultVoice() async {
  //   var voice = await _tts.getDefaultVoice;
  //   if (voice != null) {
  //     print(voice);
  //   }
  // }

  Future<void> _speack(String lang, String text) async {
    if (text.isEmpty) return;
    setState(() {
      _ttsState = _TTSState.playing;
    });
    await _tts.setLanguage(lang);
    _tts.speak(text);
    // _getDefaultVoice(); // {name: ko-KR-language, locale: ko-KR}
  }

  // Future<dynamic> _getLanguages() async => await _tts.getLanguages;
  // Future<dynamic> _getEngines() async => await _tts.getEngines;
  // Future<dynamic> _getVoices() async => await _tts.getVoices;

  void _handleChanged(String value) {
    setState(() {
      _isSearch = value.isNotEmpty;
    });
    if (value.isEmpty) {
      _debouncer.cancel();
      setState(() {
        _translated1 = '';
        _translated2 = '';
        _isSearch = false;
      });
      return;
    }
    _debouncer.run();
  }

  void _handleSubmit(String value) {
    if (value.isEmpty) return;
    _translate(value);
  }

  void _changeSource(String lang) {
    setState(() {
      _source = lang;
      _target = availableLanguage.where((element) => element != lang).toList();
      _translated1 = '';
      _translated2 = '';
      _isSearch = false;
    });
    _controller.text = '';

    Navigator.pop(context);
  }

  void _handleClear() {
    _controller.text = '';
    setState(() {
      _isSearch = false;
      _translated1 = '';
      _translated2 = '';
    });
    _focusNode.requestFocus();
  }

  void _translate(String value) {
    if (_searchedText == value) return;

    logger.d("[검색] 검색어: $value");
    Future.wait([
      _translator.translate(
        value,
        from: _source.toLowerCase(),
        to: _target[0].toLowerCase(),
      ),
      _translator.translate(
        value,
        from: _source.toLowerCase(),
        to: _target[1].toLowerCase(),
      ),
    ]).then((result) {
      setState(() {
        _translated1 = result[0].text;
        _translated2 = result[1].text;
      });
      _searchedText = value;
    });
  }

  void _showLanguageDialog(BuildContext originContext) {
    showModalBottomSheet(
      context: originContext,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var lang in availableLanguage)
                TextButton(
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: () => _changeSource(lang),
                  child: Row(
                    children: [
                      Text(lang),
                      if (lang == _source) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.done),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _copyClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
  }

  // bool _isInstalledLanguage(String lang) {
  //   if (lang == 'TH') return _isThaiInstalled;
  //   if (lang == 'EN') return _isEnglishInstalled;
  //   return _isKoreanInstalled;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_isSearch)
            IconButton(onPressed: _handleClear, icon: const Icon(Icons.clear)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                clipBehavior: Clip.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      onChanged: _handleChanged,
                      onSubmitted: _handleSubmit,
                      keyboardType: TextInputType.text,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 24),
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "입력하세요.",
                      ),
                    ),
                    if (_isSearch)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 2,
                            child: const Divider(
                              color: Colors.grey,
                              height: 2,
                              thickness: 2,
                            ),
                          ),
                        ),
                      ),
                    if (_translated1.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. ${_target[0]}:'),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _translated1,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              _TTSButton(
                                language: _target[0],
                                // isInstalled: _isInstalledLanguage(_target[0]),
                                isInstalled: true,
                                state: _ttsState,
                                onPlay: () => _speack(_target[0], _translated1),
                              ),
                              IconButton(
                                onPressed: () => _copyClipboard(_translated1),
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (_translated2.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('2. ${_target[1]}:'),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _translated2,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              _TTSButton(
                                language: _target[1],
                                // isInstalled: _isInstalledLanguage(_target[1]),
                                isInstalled: true,
                                state: _ttsState,
                                onPlay: () => _speack(_target[1], _translated2),
                              ),
                              IconButton(
                                onPressed: () => _copyClipboard(_translated2),
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FilledButton(
                        onPressed: () => _showLanguageDialog(context),
                        child: Text(_source),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FilledButton(
                        onPressed: null,
                        child: Text(_target.join(", ")),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TTSButton extends StatelessWidget {
  const _TTSButton({
    required this.language,
    required this.isInstalled,
    required this.state,
    required this.onPlay,
  });

  final String language;
  final bool isInstalled;
  final _TTSState state;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    if (isInstalled) {
      return IconButton(
        onPressed: state == _TTSState.playing ? null : onPlay,
        icon: const Icon(Icons.play_circle),
      );
    }
    return const SizedBox();
  }
}
