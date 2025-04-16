import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'dart:async'; // Import pre Future.delayed
import 'full_screen_image_viewer.dart';
import 'upravit_recept.dart';
import '../providers/recept_provider.dart';

class DetailReceptu extends StatefulWidget {
  final Map<String, dynamic> recept;

  const DetailReceptu({super.key, required this.recept});

  @override
  State<DetailReceptu> createState() => _DetailReceptuState();
}

// 1. Pridaj 'with WidgetsBindingObserver'
class _DetailReceptuState extends State<DetailReceptu>
    with WidgetsBindingObserver {
  late Map<String, dynamic> _currentRecept;
  int _currentImageIndex = 0;

  // 2. Pridaj premenné pre kľúč a stav načítania
  UniqueKey _scaffoldKey = UniqueKey();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentRecept = widget.recept;
    // 3. Pridaj observer životného cyklu
    WidgetsBinding.instance.addObserver(this);
  }

  // 4. Implementuj dispose na odstránenie observera
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 5. Implementuj didChangeAppLifecycleState pre resetovanie
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state); // Dobrá prax zavolať super metódu
    if (state == AppLifecycleState.resumed) {
      // Zobraz načítavaciu animáciu
      if (mounted) {
        // Skontroluj, či je widget stále v strome
        setState(() {
          _isLoading = true;
        });
      }

      // Simuluj oneskorenie pre načítavaciu animáciu (môžeš upraviť alebo odstrániť)
      Future.delayed(const Duration(milliseconds: 500), () {
        // Zmenšené oneskorenie
        // Resetuj widgety alebo stav po oneskorení
        if (mounted) {
          // Skontroluj znova pred setState
          setState(() {
            _scaffoldKey = UniqueKey(); // Resetuj kľúč Scaffold widgetu
            _isLoading = false; // Skry načítavaciu animáciu
          });
        }
      });
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final receptProvider = Provider.of<ReceptProvider>(context, listen: false);
    final currentIsFavorite = _currentRecept['isFavorite'] ?? 0;
    final newIsFavorite = currentIsFavorite == 1 ? 0 : 1;

    await receptProvider.toggleFavorite(_currentRecept['id']);

    // Použi 'mounted' kontrolu pred setState
    if (mounted) {
      setState(() {
        _currentRecept = Map.from(_currentRecept);
        _currentRecept['isFavorite'] = newIsFavorite;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Potvrdenie vymazania',
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            'Naozaj chcete vymazať tento recept?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Zrušiť',
                style: TextStyle(color: Colors.black54),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Vymazať', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final receptProvider = Provider.of<ReceptProvider>(
                  context,
                  listen: false,
                );
                await receptProvider.vymazatRecept(_currentRecept['id']);

                // Použi 'mounted' kontrolu pred prácou s contextom
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recept bol vymazaný!')),
                );

                Navigator.of(context).pop(); // Zatvorí dialog
                Navigator.of(context).pop(); // Vráti sa z DetailReceptu
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditRecept(BuildContext context) async {
    // Skontrolujem, či je widget stále pripojený pred navigáciou
    if (!mounted) return;

    // Skopírujem aktuálne dáta receptu, aby som neposielal priamo referenciu na stav
    final Map<String, dynamic> dataPreEditaciu = Map.from(_currentRecept);

    // Navigujem na obrazovku UpravitRecept a čakám na výsledok
    final result = await Navigator.push(
      // Používam await na počkanie výsledku
      context,
      MaterialPageRoute(
        // Vytvorím inštanciu widgetu UpravitRecept a odovzdám mu dáta
        builder: (context) => UpravitRecept(recept: dataPreEditaciu),
      ),
    );

    // Spracujem výsledok (upravený recept) po návrate z obrazovky UpravitRecept
    // Skontrolujem, či výsledok nie je null, či je to správny typ a či widget stále existuje
    if (result != null && result is Map<String, dynamic> && mounted) {
      setState(() {
        // Aktualizujem lokálny stav (_currentRecept) dátami vrátenými z úpravy
        _currentRecept = result;
        print(
          "DetailReceptu: Dáta aktualizované po úprave.",
        ); // Výpis pre kontrolu
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> imagePaths = [];
    if (_currentRecept['obrazky'] != null) {
      try {
        final dynamic obrazky = _currentRecept['obrazky'];
        if (obrazky is String) {
          imagePaths = (jsonDecode(obrazky) as List<dynamic>).cast<String>();
        } else if (obrazky is List<dynamic>) {
          imagePaths = obrazky.cast<String>();
        }
      } catch (e) {
        print('Error parsing obrazky: $e');
      }
    }

    imagePaths = imagePaths.where((path) => File(path).existsSync()).toList();

    // 6. Použi Stack na prekrytie načítavacej animácie
    return Stack(
      children: [
        Scaffold(
          // 7. Priraď kľúč k Scaffold widgetu
          key: _scaffoldKey,
          appBar: AppBar(
            backgroundColor: Colors.grey[100],
            elevation: 0,
            title: const Text('Detail receptu'),

            actions: [
              IconButton(
                icon: Icon(
                  _currentRecept['isFavorite'] == 1
                      ? Icons.star
                      : Icons.star_border,
                  color:
                      _currentRecept['isFavorite'] == 1
                          ? Colors.amber
                          : Colors.grey,
                ),
                onPressed: () => _toggleFavorite(context),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _navigateToEditRecept(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmationDialog(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image container (with consistent margin and white background)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  height: imagePaths.isNotEmpty ? 200 : null,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white, // Set background color to white
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child:
                      imagePaths.isNotEmpty
                          ? Stack(
                            children: [
                              PageView.builder(
                                itemCount: imagePaths.length,
                                onPageChanged: (index) {
                                  // Použi 'mounted' kontrolu pred setState
                                  if (mounted) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  }
                                },
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    // <-- Wrap with GestureDetector
                                    onTap: () {
                                      // Navigate to the full-screen viewer on tap
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => FullScreenImageViewer(
                                                imagePath: imagePaths[index],
                                              ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      // <-- Your existing ClipRRect
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        File(imagePaths[index]),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          // ... existing error builder ...
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                              size: 50,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 8, // Upravená pozícia pre bodky
                                left: 0,
                                right: 0,
                                child: Row(
                                  // Indikátor stránok (bodky)
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(imagePaths.length, (
                                    index,
                                  ) {
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            _currentImageIndex == index
                                                ? Colors
                                                    .white // Aktívna bodka
                                                : Colors.white.withOpacity(
                                                  0.5,
                                                ), // Neaktívna bodka
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              Positioned(
                                // Názov receptu presunutý vyššie
                                top: 16,
                                left: 16,
                                right:
                                    16, // Obmedzenie šírky, ak by bol názov dlhý
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ), // Mierne väčší padding
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(
                                      0.6,
                                    ), // Trochu tmavšie pozadie
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ), // Zaoblenejšie rohy
                                  ),
                                  child: Text(
                                    _currentRecept['nazov'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          18, // Trochu menšie písmo pre lepšie zobrazenie
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        // Jemný tieň pre lepšiu čitateľnosť
                                        Shadow(
                                          blurRadius: 2.0,
                                          color: Colors.black,
                                          offset: Offset(1.0, 1.0),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1, // Zabezpečí jeden riadok
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // Ak je text dlhší, zobrazí ...
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Container(
                            // Zobrazenie názvu, ak nie sú obrázky
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: Text(
                              _currentRecept['nazov'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),

                // Ingrediencie
                if (_currentRecept['ingrediencie'] != null &&
                    _currentRecept['ingrediencie'].isNotEmpty)
                  _buildBox(
                    child: _buildIngredientsSection(
                      'Ingrediencie:',
                      _currentRecept['ingrediencie'],
                    ),
                  ),

                // Postup
                if (_currentRecept['postup'] != null &&
                    _currentRecept['postup'].isNotEmpty)
                  _buildBox(
                    child: _buildProcedureSection(
                      'Postup:',
                      _currentRecept['postup'],
                      _currentRecept['ingrediencie'],
                    ),
                  ),

                // Poznámky
                if (_currentRecept['poznamky'] != null &&
                    _currentRecept['poznamky'].isNotEmpty)
                  _buildBox(
                    child: _buildSection(
                      'Poznámky:',
                      _currentRecept['poznamky'],
                    ),
                  ),
                const SizedBox(height: 20), // Pridaný malý odstup na konci
              ],
            ),
          ),
          backgroundColor: Colors.grey[100],
        ),
        // 8. Podmienené zobrazenie načítavacej animácie
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5), // Polopriehľadné pozadie
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue, // Môžeš prispôsobiť farbu
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- Zvyšok pomocných metód (_buildBox, _buildIngredientsSection, atď.) zostáva rovnaký ---
  Widget _buildBox({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(242, 247, 251, 1.0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIngredientsSection(String title, dynamic ingredients) {
    List<String> ingredientList = [];

    if (ingredients is String) {
      ingredientList =
          ingredients
              .split(RegExp(r'[,\n]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    } else if (ingredients is List<dynamic>) {
      // Skús skonvertovať prvky na String, ak je to možné
      ingredientList = ingredients.map((item) => item.toString()).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...ingredientList
            .map((ingredient) => _buildIngredientText(ingredient))
            .toList(),
      ],
    );
  }

  Widget _buildIngredientText(String ingredient) {
    final List<TextSpan> textSpans = [];
    // Updated RegExp to better capture units
    final RegExp exp = RegExp(
      r'(\d+(?:[.,/]\d+)?)\s*(ml|g|l|ks|pohár|čl|pl|šálka|hrniec|veľký|malý|stredný|kus|kúsok|plná|poloplná)\b',
      caseSensitive: false,
    );
    final Iterable<Match> matches = exp.allMatches(ingredient);

    int lastIndex = 0;

    for (final Match m in matches) {
      if (m.start > lastIndex) {
        textSpans.add(
          TextSpan(
            text: ingredient.substring(lastIndex, m.start),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        );
      }

      // Quantity and unit
      final String quantity = m.group(1)!;
      final String? unit = m.group(2);

      textSpans.add(
        TextSpan(
          text: quantity,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      if (unit != null) {
        // Add unit with space
        textSpans.add(
          TextSpan(
            text: ' $unit',
            style: const TextStyle(fontSize: 16, color: Colors.blue),
          ),
        );

        // Add emoji based on unit
        String? emoji;
        switch (unit.toLowerCase()) {
          case 'čl':
            emoji = '🥄'; // Spoon emoji
            break;
          case 'pl':
            emoji = '🥄'; // Spoon emoji (same as čl)
            break;
          case 'pohár':
          case 'šálka':
          case 'hrniec':
            emoji = '🥛'; // Glass/cup emoji
            break;
          case 'ks':
          case 'kus':
          case 'kúsok':
            emoji = '🍴'; // Fork and knife emoji
            break;
        }

        if (emoji != null) {
          textSpans.add(
            TextSpan(
              text: ' $emoji',
              style: const TextStyle(
                color: Colors.grey, // Gray color for emoji
                fontSize: 16,
              ),
            ),
          );
        }
      }

      lastIndex = m.end;
    }

    if (lastIndex < ingredient.length) {
      textSpans.add(
        TextSpan(
          text: ingredient.substring(lastIndex),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: '•  ',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            ...textSpans,
          ],
        ),
      ),
    );
  }

  Widget _buildProcedureSection(
    String title,
    dynamic procedure,
    dynamic ingredients,
  ) {
    List<String> ingredientList = [];
    if (ingredients is String) {
      ingredientList =
          ingredients
              .split(RegExp(r'[,\n]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    } else if (ingredients is List) {
      // Skús skonvertovať prvky na String
      ingredientList = ingredients.map((item) => item.toString()).toList();
    }

    // Extrahuj názvy ingrediencií (bez množstiev/jednotiek) - presnejší prístup
    List<String> ingredientNames =
        ingredientList
            .map((ingredient) {
              // Najprv odstráni čísla a jednotky na konci
              String name =
                  ingredient
                      .replaceAll(
                        RegExp(
                          r'\s+\d+(?:[.,/]\d+)?\s*(ml|g|l|ks|pohár|čl|pl)?$',
                        ),
                        '',
                      )
                      .trim();
              // Potom odstráni čísla a jednotky na začiatku (menej časté, ale pre istotu)
              name =
                  name
                      .replaceAll(
                        RegExp(
                          r'^\d+(?:[.,/]\d+)?\s*(ml|g|l|ks|pohár|čl|pl)?\s+',
                        ),
                        '',
                      )
                      .trim();
              return name;
            })
            .where((name) => name.isNotEmpty)
            .toList(); // Odfiltruj prázdne reťazce

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildHighlightedProcedureText(
          procedure.toString(),
          ingredientNames,
        ), // Prevod na String pre istotu
      ],
    );
  }

  Widget _buildHighlightedProcedureText(
    String procedureText,
    List<String> ingredientNames,
  ) {
    final List<TextSpan> textSpans = [];

    if (ingredientNames.isEmpty) {
      // Ak nie sú ingrediencie, vráť len obyčajný text
      return Text(
        procedureText,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.4,
        ),
      ); // Pridaná výška riadku
    }

    // Zostav regex vzor na nájdenie ktorejkoľvek ingrediencie ako celého slova
    // Zoradíme ingrediencie od najdlhšej po najkratšiu, aby sa správne našli viacslovné (napr. "hladká múka" pred "múka")
    ingredientNames.sort((a, b) => b.length.compareTo(a.length));
    final String ingredientPattern = ingredientNames
        .map((name) => RegExp.escape(name))
        .join('|');
    final RegExp exp = RegExp(
      r'\b(' + ingredientPattern + r')\b',
      caseSensitive: false,
    );

    int lastIndex = 0;
    for (final Match m in exp.allMatches(procedureText)) {
      // Text pred nájdenou ingredienciou
      if (m.start > lastIndex) {
        textSpans.add(
          TextSpan(
            text: procedureText.substring(lastIndex, m.start),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ), // Bežný štýl
          ),
        );
      }

      // Nájdená ingrediencia - zvýraznená
      textSpans.add(
        TextSpan(
          text: m.group(0), // Nájdený text ingrediencie
          style: const TextStyle(
            fontSize: 16,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ), // Zvýraznený štýl
        ),
      );

      lastIndex = m.end;
    }

    // Zvyšný text po poslednej nájdenej ingrediencii
    if (lastIndex < procedureText.length) {
      textSpans.add(
        TextSpan(
          text: procedureText.substring(lastIndex),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.4,
          ), // Bežný štýl
        ),
      );
    }

    return RichText(text: TextSpan(children: textSpans));
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.4,
          ), // Pridaná výška riadku
        ),
      ],
    );
  }
}
