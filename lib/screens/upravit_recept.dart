import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../database_helper.dart';
import '../providers/functions_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/recept_provider.dart'; // Import ReceptProvider

class UpravitRecept extends StatefulWidget {
  final Map<String, dynamic> recept;

  const UpravitRecept({super.key, required this.recept});

  @override
  State<UpravitRecept> createState() => _UpravitReceptState();
}

class _UpravitReceptState extends State<UpravitRecept> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _nazovController = TextEditingController();
  final TextEditingController _postupController = TextEditingController();
  final TextEditingController _poznamkyController = TextEditingController();

  late final FunctionsProvider functionsProvider;

  List<String> _ingrediencie = [];
  String? _novaIngrediencia;
  double? _mnozstvo;
  String _selectedUnit = '...';
  final List<String> _units = ['...', 'čajová lyžička', 'polievková lyžica', 'šálka', 'gram', 'mililiter'];

  List<String> _kategorie = [];
  String? _selectedKategoria;

  List<File> _selectedImages = [];
  bool _isStepMode = false;
  List<Map<String, dynamic>> _steps = [];

  UniqueKey _scaffoldKey = UniqueKey();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    functionsProvider = Provider.of<FunctionsProvider>(context, listen: false);
    _nacitatKategorie();
    _nacitatReceptData();
  }

  void _nacitatReceptData() {
    _nazovController.text = widget.recept['nazov'];
    _selectedKategoria = widget.recept['kategoria'];
    _postupController.text = widget.recept['postup'];
    _poznamkyController.text = widget.recept['poznamky'];
    _ingrediencie = widget.recept['ingrediencie']?.split(', ') ?? [];

    if (widget.recept['obrazky'] != null) {
      final List<dynamic> obrazkyJson = jsonDecode(widget.recept['obrazky']);
      _selectedImages = obrazkyJson.map((path) => File(path.toString())).toList();
    }

    if (widget.recept['postup'].contains('\n')) {
      _isStepMode = true;
      final lines = widget.recept['postup'].split('\n');
      for (var i = 0; i < lines.length; i++) {
        _steps.add({
          'number': i + 1,
          'text': lines[i].replaceAll('${i + 1} - ', ''),
        });
      }
    }
  }

  void _nacitatKategorie() async {
    final kategorie = await _dbHelper.getKategorie();
    setState(() {
      _kategorie = kategorie.map((k) => k['nazov'] as String).toList();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _upravitRecept() async {
    if (_nazovController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Názov receptu je povinný!')),
      );
      return;
    }

    final postupText = _isStepMode
        ? _steps.map((step) => '${step['number']} - ${step['text']}').join('\n')
        : _postupController.text;

    final updatedRecept = {
      'id': widget.recept['id'],
      'nazov': _nazovController.text,
      'kategoria': _selectedKategoria ?? widget.recept['kategoria'],
      'ingrediencie': _ingrediencie.join(', '),
      'postup': postupText,
      'poznamky': _poznamkyController.text,
      'obrazky': jsonEncode(_selectedImages.map((image) => image.path).toList()),
    };

    // Použitie ReceptProvider na aktualizáciu receptu
    final receptProvider = Provider.of<ReceptProvider>(context, listen: false);
    await receptProvider.updateRecept(updatedRecept);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recept bol aktualizovaný!')),
    );

    // Vrátiť aktualizovaný recept späť do DetailReceptu
    Navigator.pop(context, updatedRecept);
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      for (var i = 0; i < _steps.length; i++) {
        _steps[i]['number'] = i + 1;
      }
    });
  }

  void _editStep(int index) {
    final step = _steps[index];
    final TextEditingController _stepController = TextEditingController(text: step['text']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(242, 247, 251, 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Upraviť krok',
            style: TextStyle(
              color: Color.fromARGB(255, 43, 40, 40),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: TextFormField(
              controller: _stepController,
              decoration: InputDecoration(
                labelText: '...',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 43, 40, 40),
                  ),
                ),
              ),
              maxLines: null,
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
                  color: Color.fromARGB(255, 0, 0, 0),
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
                  color: Color.fromARGB(255, 90, 29, 29),
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
          backgroundColor: Color.fromRGBO(242, 247, 251, 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Pridať krok',
            style: TextStyle(
              color: Color.fromARGB(255, 43, 40, 40),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: TextFormField(
              controller: _stepController,
              decoration: InputDecoration(
                labelText: 'Text kroku',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 43, 40, 40),
                  ),
                ),
              ),
              maxLines: null,
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
                  color: Color.fromARGB(255, 0, 0, 0),
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
                  color: Color.fromARGB(255, 90, 29, 29),
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
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: ClipRRect(
                child: AppBar(
                  title: const Text('Upraviť recept'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  backgroundColor: Color.fromARGB(255, 255, 255, 255),
                  flexibleSpace: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                          child: Container(
                            color: const Color.fromARGB(0, 0, 0, 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.blue),
                      onPressed: _upravitRecept,
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: const Color.fromARGB(0, 252, 252, 252),
            body: Stack(
              key: _scaffoldKey,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: kToolbarHeight + 40,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length) {
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
                      Container(
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
                              decoration: InputDecoration(
                                hintText: _nazovController.text.isEmpty ? '...' : null,
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
                      Container(
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
                                  onPressed: () {
                                    functionsProvider.openKategoriaDialog(context, _nacitatKategorie);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
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
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            _openUpdateIngrediencieDialog(ingrediencia);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Color.fromARGB(255, 88, 88, 88)),
                                          onPressed: () {
                                            _showDeleteConfirmationDialog(ingrediencia);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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
                      Container(
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                            _postupController.text = _steps
                                                .map((step) => '${step['number']} - ${step['text']}')
                                                .join('\n');
                                          } else {
                                            _steps.clear();
                                            final lines = _postupController.text.split('\n');
                                            for (var i = 0; i < lines.length; i++) {
                                              _steps.add({
                                                'number': i + 1,
                                                'text': lines[i].replaceAll('${i + 1} - ', ''),
                                              });
                                            }
                                          }
                                        });
                                      },
                                      inactiveThumbColor: Color.fromARGB(255, 88, 88, 88),
                                      activeColor: const Color.fromARGB(255, 88, 88, 88),
                                      inactiveTrackColor: const Color.fromARGB(255, 255, 255, 255),
                                      activeTrackColor: const Color.fromARGB(255, 255, 255, 255),
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
                                itemCount: _steps.length + 1,
                                itemBuilder: (context, index) {
                                  if (index < _steps.length) {
                                    final step = _steps[index];
                                    return ListTile(
                                      title: Text('${step['number']} - ${step['text']}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () {
                                              _editStep(index);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Color.fromARGB(255, 88, 88, 88)),
                                            onPressed: () {
                                              _removeStep(index);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return ListTile(
                                      title: const Text('Pridať krok'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.add, color: Colors.blue),
                                        onPressed: _addStep,
                                      ),
                                    );
                                  }
                                },
                              ),
                            if (!_isStepMode)
                              TextFormField(
                                controller: _postupController,
                                decoration: InputDecoration(
                                  hintText: _postupController.text.isEmpty ? '...' : null,
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
                      Container(
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
                              decoration: InputDecoration(
                                hintText: _poznamkyController.text.isEmpty ? '...' : null,
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
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
          backgroundColor: Color.fromRGBO(242, 247, 251, 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Potvrdenie',
            style: TextStyle(
              color: Color.fromARGB(255, 43, 40, 40),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Naozaj chcete odstrániť túto ingredienciu?',
            style: TextStyle(
              color: Color.fromARGB(255, 43, 40, 40),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Zrušiť',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
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
                  color: Colors.red,
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
    _selectedUnit = '...';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color.fromRGBO(242, 247, 251, 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text(
                "Pridať ingredienciu",
                style: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    onChanged: (value) {
                      setStateDialog(() => _novaIngrediencia = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Názov ingrediencie',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
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
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
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
                    items: _units.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: Color.fromARGB(255, 43, 40, 40),
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
                      color: Color.fromARGB(255, 90, 29, 29),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _novaIngrediencia != null && _novaIngrediencia!.trim().isNotEmpty
                      ? () {
                          setState(() {
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
                      color: Color.fromARGB(255, 0, 0, 0),
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
    final parts = ingrediencia.split(' ');
    double? mnozstvo;
    String? jednotka;
    String nazov = '';

    if (parts.isNotEmpty) {
      nazov = parts[0];
      if (parts.length > 1) {
        mnozstvo = double.tryParse(parts[1]);
        if (mnozstvo != null && parts.length > 2) {
          jednotka = parts[2];
        } else if (parts.length > 1) {
          jednotka = parts[1];
        }
      }
    }

    if (jednotka != null && !_units.contains(jednotka)) {
      jednotka = '...';
    }

    _novaIngrediencia = nazov;
    _mnozstvo = mnozstvo;
    _selectedUnit = jednotka ?? '...';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color.fromRGBO(242, 247, 251, 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text(
                "Upraviť ingredienciu",
                style: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: nazov,
                    onChanged: (value) {
                      setStateDialog(() => _novaIngrediencia = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Názov ingrediencie',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
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
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
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
                    items: _units.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: Color.fromARGB(255, 43, 40, 40),
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
                      color: Color.fromARGB(255, 90, 29, 29),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _novaIngrediencia != null && _novaIngrediencia!.trim().isNotEmpty
                      ? () {
                          setState(() {
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
                      color: Color.fromARGB(255, 0, 0, 0),
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