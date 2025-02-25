import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import '../database_helper.dart';
import 'dart:convert';

class PridatRecept extends StatefulWidget {
  const PridatRecept({super.key});

  @override
  State<PridatRecept> createState() => _PridatReceptState();
}

class _PridatReceptState extends State<PridatRecept> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _nazovController = TextEditingController();
  final TextEditingController _kategoriaController = TextEditingController();
  final TextEditingController _postupController = TextEditingController();
  final TextEditingController _poznamkyController = TextEditingController();

  List<String> _ingrediencie = [];
  String? _novaIngrediencia;
  double? _mnozstvo;
  String _selectedUnit = 'čajová lyžička';
  final List<String> _units = ['čajová lyžička', 'polievková lyžica', 'šálka', 'gram', 'mililiter'];

  List<String> _kategorie = [];
  String? _selectedKategoria;

  List<File> _selectedImages = []; // List to store multiple images

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nacitatKategorie();
  }

  void _nacitatKategorie() async {
    final kategorie = await _dbHelper.getKategorie();
    setState(() {
      _kategorie = kategorie.map((k) => k['nazov'] as String).toList();
    });
  }

  void _pridatRecept() async {
    if (_nazovController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Názov receptu je povinný!')),
      );
      return;
    }

    final novyRecept = {
      'nazov': _nazovController.text,
      'kategoria': _selectedKategoria ?? '',
      'ingrediencie': _ingrediencie.join(', '),
      'postup': _postupController.text,
      'poznamky': _poznamkyController.text,
      'obrazky': jsonEncode(_selectedImages.map((image) => image.path).toList()), // Convert list to JSON string
    };

    await _dbHelper.insertRecept(novyRecept);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recept bol pridaný!')),
    );

    // Clear the form
    _nazovController.clear();
    _kategoriaController.clear();
    _postupController.clear();
    _poznamkyController.clear();
    setState(() {
      _ingrediencie.clear();
      _selectedKategoria = null;
      _selectedImages.clear();
    });
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
                      color: const Color.fromARGB(171, 7, 7, 7), // Neon glow color
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
                  title: const Text('Pridať recept'),
                  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      try {
        Navigator.pop(context); // Go back to MojeRecepty
      } catch (e) {
        print('Error navigating back: $e');
      }
    },
  ),
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
                      icon: const Icon(Icons.check, color: Colors.blue),
                      onPressed: _pridatRecept,
                    ),
                  ],
                ),
              ),
            ),
            // Make the Scaffold background transparent
            backgroundColor: const Color.fromARGB(0, 252, 252, 252),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
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
        color: Colors.grey.withOpacity(0.5), // Shadow color
        spreadRadius: 2, // How far the shadow spreads
        blurRadius: 5, // How blurry the shadow is
        offset: const Offset(0, 3), // Shadow offset (x, y)
      ),
    ],
                              ),
                              child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
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
        color: Colors.grey.withOpacity(0.5), // Shadow color
        spreadRadius: 2, // How far the shadow spreads
        blurRadius: 5, // How blurry the shadow is
        offset: const Offset(0, 3), // Shadow offset (x, y)
      ),
    ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Názov receptu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nazovController,
                          decoration: const InputDecoration(
                            labelText: '...',
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
        color: Colors.grey.withOpacity(0.5), // Shadow color
        spreadRadius: 2, // How far the shadow spreads
        blurRadius: 5, // How blurry the shadow is
        offset: const Offset(0, 3), // Shadow offset (x, y)
      ),
    ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kategória',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                items: _kategorie.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.blue),
                              onPressed: _openKategoriaDialog,
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
        color: Colors.grey.withOpacity(0.5), // Shadow color
        spreadRadius: 2, // How far the shadow spreads
        blurRadius: 5, // How blurry the shadow is
        offset: const Offset(0, 3), // Shadow offset (x, y)
      ),
    ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingrediencie',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _openUpdateIngrediencieDialog(ingrediencia);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(ingrediencia);
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
                                icon: const Icon(Icons.add, color: Colors.blue),
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
        color: Colors.grey.withOpacity(0.5), // Shadow color
        spreadRadius: 2, // How far the shadow spreads
        blurRadius: 5, // How blurry the shadow is
        offset: const Offset(0, 3), // Shadow offset (x, y)
      ),
    ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Postup',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _postupController,
                          decoration: const InputDecoration(
                            labelText: 'krok 1 ...',
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
        color: Colors.grey.withOpacity(0.5), // Shadow color
        spreadRadius: 2, // How far the shadow spreads
        blurRadius: 5, // How blurry the shadow is
        offset: const Offset(0, 3), // Shadow offset (x, y)
      ),
    ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Poznámky',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _poznamkyController,
                          decoration: const InputDecoration(
                            labelText: '...',
                            border: InputBorder.none,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // Add padding to avoid overlap with bottom navigation bar
                ],
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
          title: const Text('Potvrdenie'),
          content: const Text('Naozaj chcete odstrániť túto ingredienciu?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zrušiť'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _ingrediencie.remove(ingrediencia);
                });
                Navigator.pop(context);
              },
              child: const Text('Odstrániť'),
            ),
          ],
        );
      },
    );
  }

  void _openIngrediencieDialog() {
    _novaIngrediencia = null;
    _mnozstvo = null;
    _selectedUnit = _units.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Pridať ingredienciu"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    onChanged: (value) {
                      setStateDialog(() => _novaIngrediencia = value);
                    },
                    decoration: const InputDecoration(labelText: 'Názov ingrediencie'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Názov ingrediencie je povinný!';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setStateDialog(() => _mnozstvo = double.tryParse(value));
                    },
                    decoration: const InputDecoration(labelText: 'Množstvo'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Množstvo je povinné!';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedUnit,
                    onChanged: (String? newValue) {
                      setStateDialog(() => _selectedUnit = newValue!);
                    },
                    items: _units.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('❌ Zrušiť'),
                ),
                TextButton(
                  onPressed: _novaIngrediencia != null && _novaIngrediencia!.trim().isNotEmpty && _mnozstvo != null
                      ? () {
                          setState(() {
                            _ingrediencie.add("$_mnozstvo $_selectedUnit $_novaIngrediencia");
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('✅ Pridať'),
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
    final mnozstvo = double.tryParse(parts[0]);
    final jednotka = parts[1];
    final nazov = parts.sublist(2).join(' ');

    _novaIngrediencia = nazov;
    _mnozstvo = mnozstvo;
    _selectedUnit = jednotka;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Upraviť ingredienciu"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: nazov,
                    onChanged: (value) {
                      setStateDialog(() => _novaIngrediencia = value);
                    },
                    decoration: const InputDecoration(labelText: 'Názov ingrediencie'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Názov ingrediencie je povinný!';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: mnozstvo?.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setStateDialog(() => _mnozstvo = double.tryParse(value));
                    },
                    decoration: const InputDecoration(labelText: 'Množstvo'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Množstvo je povinné!';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedUnit,
                    onChanged: (String? newValue) {
                      setStateDialog(() => _selectedUnit = newValue!);
                    },
                    items: _units.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('❌ Zrušiť'),
                ),
                TextButton(
                  onPressed: _novaIngrediencia != null && _novaIngrediencia!.trim().isNotEmpty && _mnozstvo != null
                      ? () {
                          setState(() {
                            final updatedIngrediencia = "$_mnozstvo $_selectedUnit $_novaIngrediencia";
                            final index = _ingrediencie.indexOf(ingrediencia);
                            if (index != -1) {
                              _ingrediencie[index] = updatedIngrediencia;
                            }
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('✅ Uložiť'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openKategoriaDialog() {
    String? _novaKategoria;

    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Pridať kategóriu"),
              content: TextFormField(
                onChanged: (value) {
                  setStateDialog(() {
                    _novaKategoria = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Názov kategórie'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Názov kategórie je povinný!';
                  }
                  return null;
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('❌ Zrušiť'),
                ),
                TextButton(
                  onPressed: _novaKategoria != null && _novaKategoria!.trim().isNotEmpty
                      ? () async {
                          await _dbHelper.insertKategoria(_novaKategoria!);
                          _nacitatKategorie();
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('✅ Pridať'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}