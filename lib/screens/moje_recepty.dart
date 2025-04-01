// moje_recepty.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recept_provider.dart';
import '../providers/functions_provider.dart';
import 'detail_receptu.dart';
import 'pridat_recept.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:intl/intl.dart';

class MojeRecepty extends StatefulWidget {
  const MojeRecepty({super.key});

  @override
  State<MojeRecepty> createState() => _MojeReceptyState();
}

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Initialize the animation
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Color.fromRGBO(242, 247, 251, 1.0),
      child: InkWell(
        onTap: _toggleExpansion, // Ripple effect on the entire container
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
            // Expanding Content
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Align(heightFactor: _animation.value, child: child),
                );
              },
              child: Column(children: widget.children),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomDesign extends StatelessWidget {
  const BottomDesign({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        width: double.infinity, // Ensure full width
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), // Rounded top edges
            topRight: Radius.circular(20),
          ),
          child: Container(
            height: 20, // Match the height of the AppBar
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 247, 246, 246),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              image: const DecorationImage(
                image: AssetImage(
                  'lib/assets/images/22.jpg',
                ), // Background image
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 0,
                sigmaY: 0,
              ), // Adjust blur intensity
              child: Container(
                color: const Color.fromARGB(
                  0,
                  0,
                  0,
                  0,
                ), // Semi-transparent overlay
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MojeReceptyState extends State<MojeRecepty> {
  String _searchQuery = '';
  String? _selectedFilterKategoria;
  bool _isSearchVisible = false;
  // Remove favorites filter

  late FunctionsProvider functionsProvider;
  late ReceptProvider receptProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Access the providers here
    functionsProvider = Provider.of<FunctionsProvider>(context, listen: false);
    receptProvider = Provider.of<ReceptProvider>(context, listen: false);

    // Load data
    receptProvider.nacitatRecepty();
    receptProvider.nacitatKategorie();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wrap the Scaffold in a Stack to layer the neon glow and content
      body: Stack(
        children: [
          // Neon Glow Effect (wrapping around the rounded AppBar)
          Positioned(
            top:
                kToolbarHeight +
                30, // Position the glow slightly above the AppBar bottom
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 8, // Height of the glow effect
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        171,
                        7,
                        7,
                        7,
                      ), // Neon glow color
                      blurRadius: 50, // Spread of the glow
                      spreadRadius: 10, // How far the glow extends
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(125, 113, 154, 187),
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
              preferredSize: const Size.fromHeight(
                kToolbarHeight + 20,
              ), // Increase height for rounded edges
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20), // Rounded bottom edges
                  bottomRight: Radius.circular(20),
                ),
                child: AppBar(
                  title: const Text('Moje Recepty'), // AppBar title
                  backgroundColor: const Color.fromARGB(
                    255,
                    247,
                    246,
                    246,
                  ), // AppBar background color
                  elevation: 0, // Remove shadow
                  flexibleSpace: Stack(
                    children: [
                      // Background Image inside the AppBar
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(
                              20,
                            ), // Match the AppBar's rounded edges
                            bottomRight: Radius.circular(20),
                          ),
                          child: Image.asset(
                            'lib/assets/images/22.jpg', // Replace with your image path
                            fit: BoxFit.cover, // Cover the AppBar area
                          ),
                        ),
                      ),
                      // Blur Effect for the AppBar
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(
                            20,
                          ), // Match the AppBar's rounded edges
                          bottomRight: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 0,
                            sigmaY: 0,
                          ), // Adjust blur intensity
                          child: Container(
                            color: const Color.fromARGB(
                              0,
                              0,
                              0,
                              0,
                            ), // Semi-transparent overlay
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Removed star icon
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
                          MaterialPageRoute(
                            builder: (context) => const PridatRecept(),
                          ),
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
                      // Filter Text with Arrow Icon
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _showCategoryFilterDialog(
                              context,
                            ); // Show the pop-up dialog
                          },
                          style: TextButton.styleFrom(
                            alignment:
                                Alignment.centerLeft, // Align text to the left
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ), // Padding inside the button
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedFilterKategoria ??
                                    'Filtrovať podľa kategórie',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color.fromARGB(
                                    255,
                                    50,
                                    50,
                                    50,
                                  ), // Slightly gray text
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Spacing between text and arrow
                              Icon(
                                Icons.arrow_forward_ios, // Arrow icon
                                size: 14, // Icon size
                                color: const Color.fromARGB(
                                  255,
                                  50,
                                  50,
                                  50,
                                ), // Match the text color
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ), // Spacing between filter button and "Pridať" button
                      // "Pridať" Button
                      TextButton(
                        onPressed: () {
                          functionsProvider.openKategoriaDialog(context, () {
                            // Callback to refresh categories
                            receptProvider.nacitatKategorie();
                          });
                        },
                        child: const Text(
                          'Pridať',
                          style: TextStyle(
                            color:
                                Colors
                                    .blue, // Match the color of the previous icon
                            fontSize: 16, // Adjust font size as needed
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildReceptyList(receptProvider)),
              ],
            ),
          ),
          const BottomDesign(),
        ],
      ),
    );
  }

  Widget _buildReceptyList(ReceptProvider receptProvider) {
    return Consumer<ReceptProvider>(
      builder: (context, receptProvider, child) {
        final recepty = receptProvider.recepty;
        final filtrovaneRecepty =
            recepty.where((recept) {
              final matchesSearch = recept['nazov'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

              bool matchesCategoryOrFavorites;
              if (_selectedFilterKategoria == 'Obľúbené') {
                matchesCategoryOrFavorites = recept['isFavorite'] == 1;
              } else {
                matchesCategoryOrFavorites =
                    _selectedFilterKategoria == null ||
                    (_selectedFilterKategoria == 'Bez kategórie'
                        ? recept['kategoria'] == null ||
                            recept['kategoria'].isEmpty
                        : recept['kategoria'] == _selectedFilterKategoria);
              }

              return matchesSearch && matchesCategoryOrFavorites;
            }).toList();

        if (filtrovaneRecepty.isEmpty) {
          return const Center(child: Text('Žiadne recepty.'));
        }

        final kategorie = _zoskupitReceptyPodlaKategorie(filtrovaneRecepty);

        return ListView.builder(
          itemCount: kategorie.length,
          padding: const EdgeInsets.only(bottom: 40.0),
          itemBuilder: (context, index) {
            final kategoria = kategorie.keys.elementAt(index);
            final receptyVKategorii = kategorie[kategoria]!;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: CustomExpansionTile(
                title: kategoria,
                children: [
                  ...receptyVKategorii.map((recept) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: const Color.fromRGBO(242, 247, 251, 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          // Use a Row to arrange image and text
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start, // Align items to the top
                          children: [
                            _buildRecipeImage(recept), // Image on the left
                            Expanded(
                              // Take remaining space
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0, // Add vertical padding
                                ),
                                title: Text(
                                  recept['nazov'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  // Align text to the start
                                  children: [
                                    if (recept['vytvorene'] != null) ...[
                                      Text(
                                        _formatDate(recept['vytvorene']),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                    if (recept['poznamky'] != null &&
                                        recept['poznamky'].isNotEmpty) ...[
                                      //Check for null and emptiness
                                      const SizedBox(height: 4), // Add spacing
                                      Text(
                                        'Poznámky: ${recept['poznamky']}',
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 3,
                                        overflow:
                                            TextOverflow
                                                .ellipsis, // Handle long notes
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              DetailReceptu(recept: recept),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper function to format the date
  String _formatDate(String? dateString) {
    if (dateString == null) {
      return '';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(date); // Format as day.month.year
    } catch (e) {
      return ''; // Return empty string if parsing fails.
    }
  }

  Widget _buildRecipeImage(Map<String, dynamic> recept) {
    if (recept['obrazky'] != null) {
      try {
        final dynamic decodedImagePaths = jsonDecode(recept['obrazky']);
        List<String> imagePaths = [];

        if (decodedImagePaths is String) {
          imagePaths = [decodedImagePaths]; // If it's a single path
        } else if (decodedImagePaths is List<dynamic>) {
          imagePaths = decodedImagePaths.cast<String>();
        }

        // Check if the list is not empty and the first file exists
        if (imagePaths.isNotEmpty && File(imagePaths.first).existsSync()) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10), // Top-left corner
              bottomLeft: Radius.circular(10), // Bottom-left corner
            ),
            child: Image.file(
              File(imagePaths.first), // Display the *first* image
              width: 100, // Fixed width, adjust as needed
              height: 120, // Fixed height for consistency
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (e) {
        print("Error decoding or accessing image paths: $e");
        return const SizedBox(
          width: 100,
          height: 120,
          child: Icon(Icons.image),
        ); // Fallback with size
      }
    }
    return const SizedBox(
      width: 100,
      height: 120,
      child: Icon(Icons.image),
    ); // Fallback with size
  }

  Map<String, List<Map<String, dynamic>>> _zoskupitReceptyPodlaKategorie(
    List<Map<String, dynamic>> recepty,
  ) {
    final kategorie = <String, List<Map<String, dynamic>>>{};

    for (final recept in recepty) {
      // Explicitly handle "Bez kategórie"
      final kategoria =
          recept['kategoria']?.isEmpty ?? true
              ? 'Bez kategórie'
              : recept['kategoria'];
      if (!kategorie.containsKey(kategoria)) {
        kategorie[kategoria] = [];
      }
      kategorie[kategoria]!.add(recept);
    }

    return kategorie;
  }

  // Funkcia na zobrazenie dialógu pre filtrovanie podľa kategórie
  // Tento dialóg zobrazuje zoznam kategórií a umožňuje používateľovi vybrať jednu z nich

  void _showCategoryFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Používame Consumer na získanie aktuálnych dát z providera
        return Consumer<ReceptProvider>(
          builder: (context, providerData, child) {
            // Získaj aktuálne kategórie z providera
            final currentKategorie = providerData.kategorie;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              title: const Text(
                'Filtrovať podľa kategórie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Statické možnosti (Všetky, Bez kategórie, Obľúbené)
                    ListTile(
                      title: const Text('Všetky kategórie'),
                      leading: Icon(
                        Icons.clear_all,
                        color:
                            _selectedFilterKategoria == null
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedFilterKategoria = null;
                        });
                        Navigator.pop(dialogContext);
                      },
                    ),
                    ListTile(
                      title: const Text('Bez kategórie'),
                      leading: Icon(
                        Icons.label_off_outlined,
                        color:
                            _selectedFilterKategoria == 'Bez kategórie'
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedFilterKategoria = 'Bez kategórie';
                        });
                        Navigator.pop(dialogContext);
                      },
                    ),
                    ListTile(
                      title: const Text('Obľúbené'),
                      leading: Icon(
                        Icons.star_outline,
                        color:
                            _selectedFilterKategoria == 'Obľúbené'
                                ? Colors.amber
                                : Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedFilterKategoria = 'Obľúbené';
                        });
                        Navigator.pop(dialogContext);
                      },
                    ),
                    if (currentKategorie.isNotEmpty)
                      const Divider(height: 1, indent: 16, endIndent: 16),

                    // Dynamický zoznam kategórií
                    ...currentKategorie.map((kategoria) {
                      return ListTile(
                        leading: Icon(
                          Icons.label_outline,
                          color:
                              _selectedFilterKategoria == kategoria
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                        ),
                        title: Text(kategoria),
                        selected: _selectedFilterKategoria == kategoria,
                        selectedTileColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        // Pridanie tlačidla na vymazanie kategórie
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color.fromARGB(255, 46, 46, 46),
                          ),
                          tooltip: 'Vymazať kategóriu "$kategoria"',
                          onPressed: () {
                            // Najprv zavri filter dialóg
                            Navigator.pop(dialogContext);
                            // Potom zobraz potvrdenie vymazania
                            _confirmDeleteCategory(context, kategoria);
                          },
                        ),
                        onTap: () {
                          // Pôvodný onTap pre výber filtra
                          setState(() {
                            _selectedFilterKategoria = kategoria;
                          });
                          Navigator.pop(dialogContext);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Zavrieť'),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, String kategoria) {
    // Store the current filter state before async operations
    final currentFilter = _selectedFilterKategoria;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Potvrdiť vymazanie'),
          content: Text(
            'Naozaj chcete vymazať kategóriu "$kategoria"? Recepty v tejto kategórii budú presunuté do "Bez kategórie".',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Nie'),
              onPressed: () => navigator.pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Áno, vymazať'),
              onPressed: () async {
                // Close the dialog immediately
                navigator.pop();

                try {
                  await receptProvider.vymazatKategoriu(kategoria);

                  // Update UI in the next frame if widget is still mounted
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        if (currentFilter == kategoria) {
                          _selectedFilterKategoria = null;
                        }
                      });
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Kategória "$kategoria" bola vymazaná.',
                          ),
                          backgroundColor: const Color.fromARGB(
                            255,
                            61,
                            61,
                            61,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                } catch (e) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Chyba pri mazaní kategórie: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  });
                  print("Error deleting category: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }
}
