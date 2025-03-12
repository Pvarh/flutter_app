import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:provider/provider.dart';

import 'upravit_recept.dart';
import '../providers/recept_provider.dart';


class DetailReceptu extends StatefulWidget {
  final Map<String, dynamic> recept;

  const DetailReceptu({super.key, required this.recept});

  @override
  State<DetailReceptu> createState() => _DetailReceptuState();
}

class _DetailReceptuState extends State<DetailReceptu> {
  late Map<String, dynamic> _currentRecept;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentRecept = widget.recept;
  }

    Future<void> _toggleFavorite(BuildContext context) async {
  final receptProvider = Provider.of<ReceptProvider>(context, listen: false);
  // Get the current isFavorite value.  Handle the case where it might be null.
  final currentIsFavorite = _currentRecept['isFavorite'] ?? 0;
  final newIsFavorite = currentIsFavorite == 1 ? 0 : 1;

  // Update the provider *first*. This is important for consistency.
  await receptProvider.toggleFavorite(_currentRecept['id']);

  // THEN, update the local state.  Create a *new* map.  Do NOT modify the existing map.
  setState(() {
    _currentRecept = Map.from(_currentRecept); // Create a copy
    _currentRecept['isFavorite'] = newIsFavorite;
  });
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
              child:
                  const Text('Zrušiť', style: TextStyle(color: Colors.black54)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Vymazať', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final receptProvider =
                    Provider.of<ReceptProvider>(context, listen: false);
                await receptProvider.vymazatRecept(_currentRecept['id']);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recept bol vymazaný!')),
                );

                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditRecept(BuildContext context) async {
    final updatedRecept = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpravitRecept(recept: _currentRecept),
      ),
    );

    if (updatedRecept != null) {
      setState(() {
        _currentRecept = updatedRecept;
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text(
          'Detail receptu',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              _currentRecept['isFavorite'] == 1 ? Icons.star : Icons.star_border,
              color: _currentRecept['isFavorite'] == 1 ? Colors.amber : Colors.grey,
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: imagePaths.isNotEmpty ? 200 : null,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white, // Set background color to white
                boxShadow: [
                  // Add shadow
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: imagePaths.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: imagePaths.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(imagePaths[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currentRecept['nazov'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(_currentRecept['nazov'],
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
            ),

            // Ingrediencie
            if (_currentRecept['ingrediencie'] != null &&
                _currentRecept['ingrediencie'].isNotEmpty)
              _buildBox(
                child: _buildIngredientsSection(
                    'Ingrediencie:', _currentRecept['ingrediencie']),
              ),

            // Postup
            if (_currentRecept['postup'] != null &&
                _currentRecept['postup'].isNotEmpty)
              _buildBox(
                child: _buildProcedureSection(
                    'Postup:', _currentRecept['postup'], _currentRecept['ingrediencie']),
              ),

            // Poznámky
            if (_currentRecept['poznamky'] != null &&
                _currentRecept['poznamky'].isNotEmpty)
              _buildBox(
                child: _buildSection('Poznámky:', _currentRecept['poznamky']),
              ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }

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
      ingredientList = ingredients
          .split(RegExp(r'[,\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (ingredients is List<dynamic>) {
      ingredientList = ingredients.cast<String>();
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
    final RegExp exp = RegExp(
        r'(\d+(\.\d+)?|\d+/\d+)\s*(ml|g|l|ks|pohár|čl|pl)?',
        caseSensitive: false);
    final Iterable<Match> matches = exp.allMatches(ingredient);

    int lastIndex = 0;

    for (final Match m in matches) {
      if (m.start > lastIndex) {
        textSpans.add(TextSpan(
          text: ingredient.substring(lastIndex, m.start),
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ));
      }

      final String matchedText = m.group(0)!;
      textSpans.add(
        TextSpan(
          text: matchedText,
          style: const TextStyle(fontSize: 16, color: Colors.blue),
        ),
      );

      lastIndex = m.end;
    }

    if (lastIndex < ingredient.length) {
      textSpans.add(
        TextSpan(
          text: ingredient.substring(lastIndex),
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
              text: '• ',
              style: TextStyle(fontSize: 16, color: Colors.black54)),
          ...textSpans
        ],
      ),
    );
  }

  Widget _buildProcedureSection(String title, dynamic procedure, dynamic ingredients) {
       List<String> ingredientList = [];
    if (ingredients is String) {
      ingredientList = ingredients.split(RegExp(r'[,\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (ingredients is List) {
     ingredientList = List<String>.from(ingredients); // Correctly handle List
    }

     // Extract just the ingredient names (without quantities/units)
    List<String> ingredientNames = ingredientList.map((ingredient) {
    final RegExp exp = RegExp(r'(\d+(\.\d+)?|\d+/\d+)\s*(ml|g|l|ks|pohár|čl|pl)?', caseSensitive: false);
    String name = exp.firstMatch(ingredient)?.group(0) ?? ''; // Get the matched part (quantity + unit)
    return ingredient.replaceFirst(name, '').trim();       //remove quantity and unit and trim spaces
  }).toList();



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildHighlightedProcedureText(procedure, ingredientNames),
      ],
    );
  }

   Widget _buildHighlightedProcedureText(String procedureText, List<String> ingredientNames) {
    final List<TextSpan> textSpans = [];
     // Build a regex pattern to match any of the ingredient names
    final String ingredientPattern = ingredientNames.map((name) => RegExp.escape(name)).join('|'); // Escape for regex safety
    final RegExp exp = RegExp(r'\b(' + ingredientPattern + r')\b', caseSensitive: false);  // Use word boundaries (\b)


    int lastIndex = 0;
    for (final Match m in exp.allMatches(procedureText)) {
      // Text before the match
      if (m.start > lastIndex) {
        textSpans.add(TextSpan(
          text: procedureText.substring(lastIndex, m.start),
          style: const TextStyle(fontSize: 16, color: Colors.black54), // Regular style
        ));
      }

      // Matched ingredient name, colored blue
      textSpans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(fontSize: 16, color: Colors.blue),  // Blue color
      ));

      lastIndex = m.end;
    }

    // Add any remaining text after the last match
    if (lastIndex < procedureText.length) {
      textSpans.add(TextSpan(
        text: procedureText.substring(lastIndex),
        style: const TextStyle(fontSize: 16, color: Colors.black54), // Regular style
      ));
    }

    return RichText(
      text: TextSpan(
        children: textSpans,
          style: const TextStyle(fontSize: 16, color: Colors.black54)
      ),
    );
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
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }
}