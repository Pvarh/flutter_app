import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recept_provider.dart';
import 'detail_receptu.dart';
import 'pridat_recept.dart';
import 'dart:io';
import 'dart:ui'; // Import for ImageFilter

class MojeRecepty extends StatefulWidget {
  const MojeRecepty({super.key});

  @override
  State<MojeRecepty> createState() => _MojeReceptyState();
}

class _MojeReceptyState extends State<MojeRecepty> {
  String _searchQuery = '';
  String? _selectedFilterKategoria;
  bool _isSearchVisible = false;
  bool _showFavoritesOnly = false; // State for favorites filter

  @override
  void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final receptProvider = Provider.of<ReceptProvider>(context, listen: false);
    receptProvider.nacitatRecepty();
    receptProvider.nacitatKategorie();
  });
}

 @override
Widget build(BuildContext context) {
  final receptProvider = Provider.of<ReceptProvider>(context);

  return Scaffold(
    // Wrap the Scaffold in a Stack to layer the neon glow and content
    body: Stack(
      children: [
        // Neon Glow Effect (wrapping around the rounded AppBar)
        Positioned(
          top: kToolbarHeight + 30, // Position the glow slightly above the AppBar bottom
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20), // Match the AppBar's rounded edges
              bottomRight: Radius.circular(20),
            ),
            child: Container(
              height: 20, // Height of the glow effect
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 1, 135, 245).withOpacity(0.5), // Neon glow color
                    blurRadius: 20, // Spread of the glow
                    spreadRadius: 10, // How far the glow extends
                  ),
                ],
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // Scaffold with AppBar and Body
        Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 20), // Increase height for rounded edges
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20), // Rounded bottom edges
                bottomRight: Radius.circular(20),
              ),
              child: AppBar(
                title: const Text('Moje Recepty'), // AppBar title
                backgroundColor: Colors.transparent, // Make AppBar background transparent
                elevation: 0, // Remove shadow
                flexibleSpace: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20), // Match the AppBar's rounded edges
                    bottomRight: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Adjust blur intensity
                    child: Container(
                      color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = !_isSearchVisible;
                      });
                    },
                  ),
                  IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PridatRecept()),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          // Make the Scaffold background transparent
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              if (_isSearchVisible)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Hľadať recepty',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilterKategoria,
                        hint: const Text('Filtrovať podľa kategórie'),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFilterKategoria = newValue;
                          });
                        },
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Všetky kategórie'),
                          ),
                          ...receptProvider.kategorie.map<DropdownMenuItem<String>>(
                            (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            },
                          ).toList(),
                          const DropdownMenuItem<String>(
                            value: 'Bez kategórie',
                            child: Text('Bez kategórie'),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showFavoritesOnly ? Icons.star : Icons.star_border,
                        color: _showFavoritesOnly ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showFavoritesOnly = !_showFavoritesOnly;
                          if (_showFavoritesOnly) {
                            // Reset search and category filters when showing favorites
                            _searchQuery = '';
                            _selectedFilterKategoria = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildReceptyList(receptProvider)),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildReceptyList(ReceptProvider receptProvider) {
  return Consumer<ReceptProvider>(
    builder: (context, receptProvider, child) {
      final recepty = receptProvider.recepty;
      final filtrovaneRecepty = recepty.where((recept) {
        final matchesSearch = recept['nazov'].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        final matchesCategory =
            _selectedFilterKategoria == null ||
                (_selectedFilterKategoria == 'Bez kategórie'
                    ? recept['kategoria'] == null || recept['kategoria'].isEmpty
                    : recept['kategoria'] == _selectedFilterKategoria);
        final matchesFavorites =
            !_showFavoritesOnly || recept['isFavorite'] == 1;
        return matchesSearch && matchesCategory && matchesFavorites;
      }).toList();

      if (filtrovaneRecepty.isEmpty) {
        return const Center(child: Text('Žiadne recepty.'));
      }

      final kategorie = _zoskupitReceptyPodlaKategorie(filtrovaneRecepty);

      return ListView.builder(
        itemCount: kategorie.length,
        itemBuilder: (context, index) {
          final kategoria = kategorie.keys.elementAt(index);
          final receptyVKategorii = kategorie[kategoria]!;

          return ExpansionTile(
            title: Text(kategoria),
            children: [
              ...receptyVKategorii.map((recept) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: recept['obrazokPath'] != null
                        ? Image.file(
                            File(recept['obrazokPath']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image,
                            size: 50,
                          ), // Placeholder if no image
                    title: Text(recept['nazov']),
                    subtitle: Text(recept['vytvorene'] ?? ''),
                    trailing: IconButton(
                      icon: Icon(
                        recept['isFavorite'] == 1
                            ? Icons.star
                            : Icons.star_border,
                        color: recept['isFavorite'] == 1
                            ? Colors.amber
                            : Colors.grey,
                      ),
                      onPressed: () {
                        receptProvider.toggleFavorite(recept['id']);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailReceptu(recept: recept),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          );
        },
      );
    },
  );
}

  Map<String, List<Map<String, dynamic>>> _zoskupitReceptyPodlaKategorie(
    List<Map<String, dynamic>> recepty,
  ) {
    final kategorie = <String, List<Map<String, dynamic>>>{};

    for (final recept in recepty) {
      final kategoria = recept['kategoria'] ?? 'Bez kategórie';
      if (!kategorie.containsKey(kategoria)) {
        kategorie[kategoria] = [];
      }
      kategorie[kategoria]!.add(recept);
    }

    return kategorie;
  }
}