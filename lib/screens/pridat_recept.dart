import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../database_helper.dart';

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
  String _selectedUnit = 'lyžička';
  final List<String> _units = ['lyžička', 'polievková lyžica', 'šálka', 'gram', 'mililiter'];

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
      'obrazky': _selectedImages.map((image) => image.path).toList(), // Save image paths
    };

    await _dbHelper.insertRecept(novyRecept);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recept bol pridaný!')),
    );

    // Vyčistenie polí po uložení
    _nazovController.clear();
    _kategoriaController.clear();
    _postupController.clear();
    _poznamkyController.clear();
    setState(() {
      _ingrediencie.clear();
      _selectedKategoria = null;
      _selectedImages.clear(); // Clear the selected images
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pridať recept'),
      ),
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
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
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
            TextFormField(
              controller: _nazovController,
              decoration: const InputDecoration(labelText: 'Názov receptu'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Názov receptu je povinný!';
                }
                return null;
              },
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Ingrediencie'),
                    controller: TextEditingController(text: _ingrediencie.join(", ")),
                ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: _openIngrediencieDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      if (_ingrediencie.isNotEmpty) {
                        _ingrediencie.removeLast();
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _postupController,
              decoration: const InputDecoration(labelText: 'Postup'),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Postup je povinný!';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _poznamkyController,
              decoration: const InputDecoration(labelText: 'Poznámky'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pridatRecept,
              child: const Text('Pridať recept'),
            ),
          ],
        ),
      ),
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