import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/l10n/app_localizations.dart';
import 'package:football_app/providers/language_provider.dart';
import 'package:football_app/screens/home.dart';

class LanguageScreen extends StatefulWidget {
  final bool isFirstTime;
  const LanguageScreen({super.key, this.isFirstTime = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';
  
  // Mapping display names to language codes
  final Map<String, String> _languageCodes = {
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Italian': 'it',
    'Portuguese': 'pt',
    'Arabic': 'ar',
    'Chinese': 'zh',
    'Hindi': 'hi',
    'Japanese': 'ja',
    'Swahili': 'sw',
    'Amharic': 'am',
    'Yoruba': 'yo',
    'Quechua': 'qu',
  };

  final Map<String, List<String>> _languages = {
    'Europe': ['English', 'Spanish', 'French', 'German', 'Italian'],
    'Africa': ['Swahili', 'Amharic', 'Yoruba'],
    'Americas': ['Portuguese', 'Quechua'],
    'Asia': ['Arabic', 'Chinese', 'Hindi', 'Japanese'],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LanguageProvider>();
      final currentCode = provider.locale.languageCode;
      setState(() {
        _selectedLanguage = _languageCodes.entries
            .firstWhere((e) => e.value == currentCode, 
                orElse: () => _languageCodes.entries.first)
            .key;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    const Color accentColor = Color(0xFFFF8700);
    final languageProvider = context.read<LanguageProvider>();

    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: Text(l10n.selectLanguage),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          automaticallyImplyLeading: !widget.isFirstTime,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  String continent = _languages.keys.elementAt(index);
                  List<String> langList = _languages[continent]!;
      
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 24, bottom: 12),
                        child: Text(
                          continent,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: langList.map((lang) {
                              final bool isSelected = _selectedLanguage == lang;
                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                    title: Text(
                                      lang,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle, color: accentColor)
                                        : null,
                                    onTap: () {
                                      setState(() => _selectedLanguage = lang);
                                      final code = _languageCodes[lang] ?? 'en';
                                      languageProvider.changeLanguage(code);
                                    },
                                  ),
                                  if (lang != langList.last)
                                    Divider(
                                      height: 1,
                                      indent: 20,
                                      endIndent: 20,
                                      color: isDark ? Colors.white10 : Colors.black12,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (widget.isFirstTime)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (context) => const Home())
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.continueLabel,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
