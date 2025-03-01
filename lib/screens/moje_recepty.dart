import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recept_provider.dart';
import '../providers/functions_provider.dart';
import 'detail_receptu.dart';
import 'pridat_recept.dart';
import 'dart:io';
import 'dart:ui'; // Import for ImageFilter

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
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
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
                  child: Align(
                    heightFactor: _animation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: widget.children,
              ),
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
  bool _showFavoritesOnly = false; // State for favorites filter

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
            top: kToolbarHeight + 30, // Position the glow slightly above the AppBar bottom
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 20, // Height of the glow effect
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
              preferredSize: const Size.fromHeight(kToolbarHeight + 20), // Increase height for rounded edges
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20), // Rounded bottom edges
                  bottomRight: Radius.circular(20),
                ),
                child: AppBar(
                  title: const Text('Moje Recepty'), // AppBar title
                  backgroundColor: const Color.fromARGB(255, 247, 246, 246), // AppBar background color
                  elevation: 0, // Remove shadow
                  flexibleSpace: Stack(
                    children: [
                      // Background Image inside the AppBar
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20), // Match the AppBar's rounded edges
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
                          bottomLeft: Radius.circular(20), // Match the AppBar's rounded edges
                          bottomRight: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0), // Adjust blur intensity
                          child: Container(
                            color: const Color.fromARGB(0, 0, 0, 0), // Semi-transparent overlay
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _showFavoritesOnly ? Icons.star : Icons.star_border,
                        color: _showFavoritesOnly ? Colors.amber : const Color.fromARGB(255, 88, 88, 88),
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
    // Filter Text with Arrow Icon
    Expanded(
      child: TextButton(
        onPressed: () {
          _showCategoryFilterDialog(context); // Show the pop-up dialog
        },
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft, // Align text to the left
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding inside the button
        ),
        child: Row(
          children: [
            Text(
              _selectedFilterKategoria ?? 'Filtrovať podľa kategórie',
              style: TextStyle(
                fontSize: 16,
                color: const Color.fromARGB(255, 50, 50, 50), // Slightly gray text
              ),
            ),
            const SizedBox(width: 8), // Spacing between text and arrow
            Icon(
              Icons.arrow_forward_ios, // Arrow icon
              size: 14, // Icon size
              color: const Color.fromARGB(255, 50, 50, 50), // Match the text color
            ),
          ],
        ),
      ),
    ),
    const SizedBox(width: 10), // Spacing between filter button and "Pridať" button
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
          color: Colors.blue, // Match the color of the previous icon
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

            return Padding(
              
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0, // Add horizontal padding
                vertical: 8.0, // Add vertical padding
              ),
              child: CustomExpansionTile(
                
                title: kategoria,
                children: [
                  ...receptyVKategorii.map((recept) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, // Add horizontal padding
                        vertical: 8.0, // Add vertical padding
                      ),
                      child: Card(
                        margin: EdgeInsets.zero, // Remove default margin
                        color: Color.fromRGBO(242, 247, 251, 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, // Add padding inside the ListTile
                          ),
                          leading: recept['obrazokPath'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8), // Rounded corners for image
                                  child: Image.file(
                                    File(recept['obrazokPath']),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.image,
                                  size: 50,
                                ), // Placeholder if no image
                          title: Text(
                            recept['nazov'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            recept['vytvorene'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
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

  Map<String, List<Map<String, dynamic>>> _zoskupitReceptyPodlaKategorie(
  List<Map<String, dynamic>> recepty,
) {
  final kategorie = <String, List<Map<String, dynamic>>>{};

  for (final recept in recepty) {
    // Explicitly handle "Bez kategórie"
    final kategoria = recept['kategoria']?.isEmpty ?? true
        ? 'Bez kategórie'
        : recept['kategoria'];
    if (!kategorie.containsKey(kategoria)) {
      kategorie[kategoria] = [];
    }
    kategorie[kategoria]!.add(recept);
  }

  return kategorie;
}

void _showCategoryFilterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Fit the content
          children: [
            const Text(
              'Vyberte kategóriu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...receptProvider.kategorie.map((kategoria) {
              return ListTile(
                title: Text(kategoria),
                onTap: () {
                  setState(() {
                    _selectedFilterKategoria = kategoria;
                  });
                  Navigator.pop(context); // Close the dialog
                },
              );
            }).toList(),
            ListTile(
              title: const Text('Všetky kategórie'),
              onTap: () {
                setState(() {
                  _selectedFilterKategoria = null; // Reset filter
                });
                Navigator.pop(context); // Close the dialog
              },
            ),
            ListTile(
              title: const Text('Bez kategórie'),
              onTap: () {
                setState(() {
                  _selectedFilterKategoria = 'Bez kategórie';
                });
                Navigator.pop(context); // Close the dialog
              },
            ),
          ],
        ),
      );
    },
  );
}
}