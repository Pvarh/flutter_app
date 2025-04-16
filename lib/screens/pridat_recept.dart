import 'package:flutter/material.dart';
import '../providers/recept_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import '../database_helper.dart';
import 'dart:convert';
import '../providers/functions_provider.dart';

class PridatRecept extends StatefulWidget {
  const PridatRecept({super.key});

  @override
  State<PridatRecept> createState() => _PridatReceptState();
}

bool _isStepMode = false; // Toggle for step-by-step mode
List<Map<String, dynamic>> _steps = []; // List to store steps

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

class _PridatReceptState extends State<PridatRecept>
    with WidgetsBindingObserver {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _nazovController = TextEditingController();
  final TextEditingController _kategoriaController = TextEditingController();
  final TextEditingController _postupController = TextEditingController();
  final TextEditingController _poznamkyController = TextEditingController();

  late final FunctionsProvider functionsProvider;

  List<String> _ingrediencie = [];
  String? _novaIngrediencia;
  double? _mnozstvo;
  String _selectedUnit = '...'; // Default unit
  final List<String> _units = [
    '...', // Default unit
    'čl',
    'pl',
    'pohár',
    'g',
    'ml',
    'l',
    'ks',
  ];

  List<String> _kategorie = [];
  String? _selectedKategoria;

  List<File> _selectedImages = []; // List to store multiple images

  UniqueKey _scaffoldKey = UniqueKey();
  bool _isLoading = false; // Flag to control loading animation

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    functionsProvider = Provider.of<FunctionsProvider>(context, listen: false); // Initialize FunctionsProvider
    _nacitatKategorie();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Show loading animation
      setState(() {
        _isLoading = true;
      });

      // Simulate a delay for the loading animation
      Future.delayed(const Duration(seconds: 1), () {
        // Reset the widgets or state after the delay
        setState(() {
          _scaffoldKey = UniqueKey(); // Reset the Scaffold key
          _isLoading = false; // Hide loading animation
        });
      });
    }
  }

  // Function to pick an image from the gallery
 Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    setState(() {
      _selectedImages.add(File(pickedFile.path));
      print('Selected Images: $_selectedImages'); // Debug print
    });
  }
    setState(() {
      _scaffoldKey = UniqueKey(); // Generate a new Key
    });
  }

  void _nacitatKategorie() async {
    final kategorie = await _dbHelper.getKategorie();
    setState(() {
      _kategorie = kategorie.map((k) => k['nazov'] as String).toList();
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index); // Remove the step at the specified index
      // Update the step numbers for the remaining steps
      for (var i = 0; i < _steps.length; i++) {
        _steps[i]['number'] = i + 1; // Reassign step numbers sequentially
      }
    });
  }

  void _pridatRecept() async {
    if (_nazovController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Názov receptu je povinný!')),
      );
      return;
    }

    final postupText =
        _isStepMode
            ? _steps
                .map((step) => '${step['number']} - ${step['text']}')
                .join('\n') // Combine steps
            : _postupController.text; // Use plain text

    final novyRecept = {
      'nazov': _nazovController.text,
      'kategoria': _selectedKategoria ?? '',
      'ingrediencie': _ingrediencie.join(', '),
      'postup': postupText, // Save postup in the correct format
      'poznamky': _poznamkyController.text,
      'obrazky': jsonEncode(
        _selectedImages.map((image) => image.path).toList(),
      ),
    };

    await _dbHelper.insertRecept(novyRecept);

    if (!mounted) return;

    // Refresh the ReceptProvider to load the latest recipes
    final receptProvider = Provider.of<ReceptProvider>(context, listen: false);
    await receptProvider.nacitatRecepty();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recept bol pridaný!')));

    // Clear the form
    _nazovController.clear();
    _kategoriaController.clear();
    _postupController.clear();
    _poznamkyController.clear();
    setState(() {
      _ingrediencie.clear();
      _selectedKategoria = null;
      _selectedImages.clear();
      _steps.clear();
    });

    // Navigate back to MojeRecepty
    Navigator.pop(context);
  }

  void _editStep(int index) {
    final step = _steps[index];
    final TextEditingController _stepController = TextEditingController(
      text: step['text'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(
            242,
            247,
            251,
            1.0,
          ), // Match your widget background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          title: const Text(
            'Upraviť krok',
            style: TextStyle(
              color: Color.fromARGB(255, 43, 40, 40), // Dark text color
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: TextFormField(
              controller: _stepController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: '...',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40), // Dark text color
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 43, 40, 40), // Dark border
                  ),
                ),
              ),
              maxLines: null, // Allow unlimited lines
              keyboardType: TextInputType.multiline,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _steps[index]['text'] = _stepController.text;
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Uložiť',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0), // Black text for save
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                '✖',
                style: TextStyle(
                  color: Color.fromARGB(255, 90, 29, 29), // Red text for cancel
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addStep() {
    final TextEditingController _stepController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(
            242,
            247,
            251,
            1.0,
          ), // Match your widget background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          title: const Text(
            'Pridať krok',
            style: TextStyle(
              color: Color.fromARGB(255, 43, 40, 40), // Dark text color
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: TextFormField(
              controller: _stepController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Text kroku',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40), // Dark text color
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 43, 40, 40), // Dark border
                  ),
                ),
              ),
              maxLines: null, // Allow unlimited lines
              keyboardType: TextInputType.multiline,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _steps.add({
                    'number': _steps.length + 1,
                    'text': _stepController.text,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Pridať',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0), // Black text for add
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                '✖',
                style: TextStyle(
                  color: Color.fromARGB(255, 90, 29, 29), // Red text for cancel
                ),
              ),
            ),
          ],
        );
      },
    );
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
              preferredSize: const Size.fromHeight(
                kToolbarHeight + 20,
              ), // Increase height for rounded edges
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20), // Rounded bottom edges
                  bottomRight: Radius.circular(20),
                ),
                child: AppBar(
                  title: const Text('Pridať recept'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      try {
                        Navigator.pop(context); // Go back to MojeRecepty
                      } catch (e) {
                        print('Error 11: $e');
                      }
                    },
                  ),
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
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.blue),
                      onPressed: _pridatRecept,
                    ),
                  ],
                ),
              ),
            ),
            // Make the Scaffold background transparent
            backgroundColor: const Color.fromARGB(0, 252, 252, 252),
            body: Stack(
              key: _scaffoldKey,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom:
                        kToolbarHeight +
                        40, // Add padding to avoid overlap with the bottom widget
                  ),
                  child: Column(
                    children: [
                      // Your existing content here

                      // Image picker section
SizedBox(
  height: 100, // Fixed height for the image carousel
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: _selectedImages.length + 1, // +1 for the add button
    itemBuilder: (context, index) {
      if (index == _selectedImages.length) {
        // Add button
        return GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 100,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(242, 247, 251, 1.0),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_a_photo,
              size: 40,
              color: Colors.grey,
            ),
          ),
        );
      } else {
        // Display selected images
        return Container(
          width: 100,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: FileImage(_selectedImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    },
  ),
),
                      const SizedBox(height: 20),
                      // Názov receptu in a rounded rectangle
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(242, 247, 251, 1.0),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                0.5,
                              ), // Shadow color
                              spreadRadius: 2, // How far the shadow spreads
                              blurRadius: 5, // How blurry the shadow is
                              offset: const Offset(
                                0,
                                3,
                              ), // Shadow offset (x, y)
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Názov receptu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _nazovController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText:
                                    _nazovController.text.isEmpty
                                        ? '...'
                                        : null, // Use hintText instead of labelText
                                border: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Názov receptu je povinný!';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Kategória in a rounded rectangle
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(242, 247, 251, 1.0),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                0.5,
                              ), // Shadow color
                              spreadRadius: 2, // How far the shadow spreads
                              blurRadius: 5, // How blurry the shadow is
                              offset: const Offset(
                                0,
                                3,
                              ), // Shadow offset (x, y)
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategória',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _selectedKategoria,
                                    hint: const Text('Vyberte kategóriu'),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedKategoria = newValue;
                                      });
                                    },
                                    items:
                                        _kategorie
                                            .map<DropdownMenuItem<String>>((
                                              String value,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            })
                                            .toList(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.blue,
                                  ),
                                  onPressed: (){
                                    functionsProvider.openKategoriaDialog(context, _nacitatKategorie);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Ingrediencie in a rounded rectangle
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(242, 247, 251, 1.0),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                0.5,
                              ), // Shadow color
                              spreadRadius: 2, // How far the shadow spreads
                              blurRadius: 5, // How blurry the shadow is
                              offset: const Offset(
                                0,
                                3,
                              ), // Shadow offset (x, y)
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ingrediencie',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Column(
                              children: [
                                ..._ingrediencie.map((ingrediencia) {
                                  return ListTile(
                                    title: Text(ingrediencia),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            _openUpdateIngrediencieDialog(
                                              ingrediencia,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Color.fromARGB(
                                              255,
                                              88,
                                              88,
                                              88,
                                            ),
                                          ),
                                          onPressed: () {
                                            _showDeleteConfirmationDialog(
                                              ingrediencia,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                // Empty row with plus icon to add new ingredient
                                ListTile(
                                  title: const Text('Pridať ingredienciu'),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.blue,
                                    ),
                                    onPressed: _openIngrediencieDialog,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Postup in a rounded rectangle
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(242, 247, 251, 1.0),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                0.5,
                              ), // Shadow color
                              spreadRadius: 2, // How far the shadow spreads
                              blurRadius: 5, // How blurry the shadow is
                              offset: const Offset(
                                0,
                                3,
                              ), // Shadow offset (x, y)
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Postup heading with Krokovanie toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Postup',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text('Krokovanie'),
                                    Switch(
                                      value: _isStepMode,
                                      onChanged: (value) {
                                        setState(() {
                                          _isStepMode = value;
                                          if (!_isStepMode) {
                                            // Combine steps into a single string when switching to single-text-field mode
                                            _postupController.text = _steps
                                                .map(
                                                  (step) =>
                                                      '${step['number']} - ${step['text']}',
                                                )
                                                .join('\n');
                                          } else {
                                            // Parse the text into steps when switching to step-by-step mode
                                            _steps.clear();
                                            final lines = _postupController.text
                                                .split('\n');
                                            for (
                                              var i = 0;
                                              i < lines.length;
                                              i++
                                            ) {
                                              _steps.add({
                                                'number': i + 1,
                                                'text': lines[i].replaceAll(
                                                  '${i + 1} - ',
                                                  '',
                                                ), // Remove step numbers if present
                                              });
                                            }
                                          }
                                        });
                                      },
                                      inactiveThumbColor: Color.fromARGB(
                                        255,
                                        88,
                                        88,
                                        88,
                                      ),
                                      activeColor: const Color.fromARGB(
                                        255,
                                        88,
                                        88,
                                        88,
                                      ), // Toggle color
                                      inactiveTrackColor: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ), // Toggle track color
                                      activeTrackColor: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ), // Toggle track color
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_isStepMode)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    _steps.length +
                                    1, // +1 for the "Add Step" button
                                itemBuilder: (context, index) {
                                  if (index < _steps.length) {
                                    // Display existing steps
                                    final step = _steps[index];
                                    return ListTile(
                                      title: Text(
                                        '${step['number']} - ${step['text']}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ), // Edit button
                                            onPressed: () {
                                              _editStep(index);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Color.fromARGB(
                                                255,
                                                88,
                                                88,
                                                88,
                                              ),
                                            ), // Remove button
                                            onPressed: () {
                                              _removeStep(
                                                index,
                                              ); // Call the method to remove the step
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    // Display "Add Step" button
                                    return ListTile(
                                      title: const Text('Pridať krok'),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.blue,
                                        ),
                                        onPressed: _addStep,
                                      ),
                                    );
                                  }
                                },
                              ),
                            if (!_isStepMode)
                              TextFormField(
                                controller: _postupController,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText:
                                      _postupController.text.isEmpty
                                          ? '...'
                                          : null, // Use hintText instead of labelText
                                  border: InputBorder.none,
                                ),
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Postup je povinný!';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      // Poznámky in a rounded rectangle
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(242, 247, 251, 1.0),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(
                                0.5,
                              ), // Shadow color
                              spreadRadius: 2, // How far the shadow spreads
                              blurRadius: 5, // How blurry the shadow is
                              offset: const Offset(
                                0,
                                3,
                              ), // Shadow offset (x, y)
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Poznámky',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _poznamkyController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText:
                                    _poznamkyController.text.isEmpty
                                        ? '...'
                                        : null, // Use hintText instead of labelText
                                border: InputBorder.none,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                    ],
                  ),
                ),
                // Add the BottomDesign widget at the bottom
                const BottomDesign(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(
                0.5,
              ), // Semi-transparent background
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue,
                  ), // Customize color
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String ingrediencia) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(
            242,
            247,
            251,
            1.0,
          ), // Match your widget background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          title: const Text(
            'Potvrdenie',
            style: TextStyle(
              color: Color.fromARGB(255, 43, 40, 40), // Dark text color
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Naozaj chcete odstrániť túto ingredienciu?',
            style: TextStyle(
              color: Color.fromARGB(255, 43, 40, 40), // Dark text color
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Zrušiť',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0), // Blue text for cancel
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _ingrediencie.remove(ingrediencia);
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Odstrániť',
                style: TextStyle(
                  color: Colors.red, // Red text for delete
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openIngrediencieDialog() {
    _novaIngrediencia = null;
    _mnozstvo = null;
    _selectedUnit = '...'; // Default unit

  
    showDialog(
      
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color.fromRGBO(
                242,
                247,
                251,
                1.0,
              ), // Match your widget background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              title: const Text(
                "Pridať ingredienciu",
                style: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40), // Dark text color
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      setStateDialog(() => _novaIngrediencia = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Názov ingrediencie',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(
                          255,
                          43,
                          40,
                          40,
                        ), // Dark text color
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Rounded corners
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40), // Dark border
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setStateDialog(() => _mnozstvo = double.tryParse(value));
                    },
                    decoration: InputDecoration(
                      labelText: 'Množstvo (voliteľné)',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(
                          255,
                          43,
                          40,
                          40,
                        ), // Dark text color
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Rounded corners
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40), // Dark border
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedUnit,
                    onChanged: (String? newValue) {
                      setStateDialog(() => _selectedUnit = newValue!);
                    },
                    items:
                        _units.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Color.fromARGB(
                                  255,
                                  43,
                                  40,
                                  40,
                                ), // Dark text color
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '✖',
                    style: TextStyle(
                      color: Color.fromARGB(
                        255,
                        90,
                        29,
                        29,
                      ), // Blue text for cancel
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _novaIngrediencia != null &&
                              _novaIngrediencia!.trim().isNotEmpty
                          ? () {
                            setState(() {
                              // Format the ingredient string: ingredient amount unit
                              String ingredientString = _novaIngrediencia!;
                              if (_mnozstvo != null) {
                                ingredientString += ' $_mnozstvo';
                              }
                              if (_selectedUnit != '...') {
                                ingredientString += ' $_selectedUnit';
                              }

                              _ingrediencie.add(ingredientString.trim());
                            });
                            Navigator.pop(context);
                          }
                          : null,
                  child: const Text(
                    'Pridať',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0), // Green text for add
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openUpdateIngrediencieDialog(String ingrediencia) {
    // Split the ingredient into parts
    final parts = ingrediencia.split(' ');
    double? mnozstvo;
    String? jednotka;
    String nazov = '';

    // Parse the ingredient, amount, and unit
    if (parts.isNotEmpty) {
      nazov = parts[0]; // The first part is always the ingredient name
      if (parts.length > 1) {
        // Check if the second part is a number (amount)
        mnozstvo = double.tryParse(parts[1]);
        if (mnozstvo != null && parts.length > 2) {
          // The third part is the unit
          jednotka = parts[2];
        } else if (parts.length > 1) {
          // If the second part is not a number, it's the unit
          jednotka = parts[1];
        }
      }
    }

    // Ensure the unit is valid
    if (jednotka != null && !_units.contains(jednotka)) {
      jednotka = '...'; // Default to '...' if the unit is invalid
    }

    _novaIngrediencia = nazov;
    _mnozstvo = mnozstvo;
    _selectedUnit =
        jednotka ?? '...'; // Default to '...' if no unit is specified

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color.fromRGBO(
                242,
                247,
                251,
                1.0,
              ), // Match your widget background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              title: const Text(
                "Upraviť ingredienciu",
                style: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40), // Dark text color
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: nazov,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      setStateDialog(() => _novaIngrediencia = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Názov ingrediencie',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(
                          255,
                          43,
                          40,
                          40,
                        ), // Dark text color
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Rounded corners
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40), // Dark border
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: mnozstvo?.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setStateDialog(() => _mnozstvo = double.tryParse(value));
                    },
                    decoration: InputDecoration(
                      labelText: 'Množstvo (voliteľné)',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(
                          255,
                          43,
                          40,
                          40,
                        ), // Dark text color
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Rounded corners
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40), // Dark border
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedUnit,
                    onChanged: (String? newValue) {
                      setStateDialog(() => _selectedUnit = newValue!);
                    },
                    items:
                        _units.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Color.fromARGB(
                                  255,
                                  43,
                                  40,
                                  40,
                                ), // Dark text color
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '✖',
                    style: TextStyle(
                      color: Color.fromARGB(
                        255,
                        90,
                        29,
                        29,
                      ), // Red text for cancel
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _novaIngrediencia != null &&
                              _novaIngrediencia!.trim().isNotEmpty
                          ? () {
                            setState(() {
                              // Format the ingredient string: ingredient amount unit
                              String ingredientString = _novaIngrediencia!;
                              if (_mnozstvo != null) {
                                ingredientString += ' $_mnozstvo';
                              }
                              if (_selectedUnit != '...') {
                                ingredientString += ' $_selectedUnit';
                              }

                              final index = _ingrediencie.indexOf(ingrediencia);
                              if (index != -1) {
                                _ingrediencie[index] = ingredientString.trim();
                              }
                            });
                            Navigator.pop(context);
                          }
                          : null,
                  child: const Text(
                    'Uložiť',
                    style: TextStyle(
                      color: Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ), // Black text for save
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  
}
