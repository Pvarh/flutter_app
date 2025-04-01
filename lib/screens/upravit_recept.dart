import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../database_helper.dart';
import '../providers/functions_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/recept_provider.dart';
import 'dart:async';

class UpravitRecept extends StatefulWidget {
  final Map<String, dynamic> recept;

  const UpravitRecept({super.key, required this.recept});

  @override
  State<UpravitRecept> createState() => _UpravitReceptState();
}

// === ChangeNotifier pre stav formulára ===
class EditReceptNotifier with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final Map<String, dynamic>
  _initialReceptData; // Pôvodné dáta na porovnanie/reset
  final ReceptProvider _receptProvider; // Na volanie updateRecept

  // Controllery pre textové polia
  final TextEditingController nazovController = TextEditingController();
  final TextEditingController postupController = TextEditingController();
  final TextEditingController poznamkyController = TextEditingController();

  // Stavové premenné formulára
  List<String> ingrediencie = [];
  List<String> vsetkyKategorie = []; // Zoznam všetkých kategórií z DB
  String? selectedKategoria;
  List<File> selectedImages = [];
  bool isStepMode = false;
  List<Map<String, dynamic>> steps = [];
  bool isLoading = false;

  // Pomocné premenné pre dialógy
  String selectedUnit = '...'; // Pre dialógy ingrediencií
  final List<String> units = const [
    '...',
    'čl',
    'pl',
    'pohár',
    'g',
    'ml',
    'l',
    'ks',
  ];

  // Konštruktor
  EditReceptNotifier({
    required Map<String, dynamic> initialData,
    required DatabaseHelper dbHelper,
    required ReceptProvider receptProvider,
  }) : _initialReceptData = Map.from(initialData), // Kópia pôvodných dát
       _dbHelper = dbHelper,
       _receptProvider = receptProvider {
    _initializeData(); // Inicializujem stav z pôvodných dát
    _loadKategorieFromDb(); // Načítam kategórie
  }

  // Inicializujem stav notifiera z dát receptu
  void _initializeData() {
    nazovController.text = _initialReceptData['nazov'] ?? '';
    selectedKategoria = _initialReceptData['kategoria'];
    postupController.text = _initialReceptData['postup'] ?? '';
    poznamkyController.text = _initialReceptData['poznamky'] ?? '';

    final dynamic ingredientsData = _initialReceptData['ingrediencie'];
    if (ingredientsData is String && ingredientsData.isNotEmpty) {
      ingrediencie =
          ingredientsData.split(', ').where((s) => s.isNotEmpty).toList();
    } else {
      ingrediencie = [];
    }

    if (_initialReceptData['obrazky'] != null &&
        _initialReceptData['obrazky'].isNotEmpty) {
      try {
        final List<dynamic> obrazkyJson = jsonDecode(
          _initialReceptData['obrazky'],
        );
        selectedImages =
            obrazkyJson
                .map((path) => File(path.toString()))
                .where((file) => file.existsSync())
                .toList();
      } catch (e) {
        selectedImages = [];
        print("Chyba parse obrázky: $e");
      }
    } else {
      selectedImages = [];
    }

    final postupText = _initialReceptData['postup'] ?? '';
    if (postupText.contains('\n') ||
        RegExp(r'^\d+\s*[-.)]?\s*').hasMatch(postupText)) {
      isStepMode = true;
      _textToSteps();
    } else {
      isStepMode = false;
    }
    // notifyListeners(); // Notifikujem po inicializácii (voliteľné, záleží kedy sa UI naviaže)
  }

  // Načítam všetky kategórie z DB
  Future<void> _loadKategorieFromDb() async {
    final kategorieData = await _dbHelper.getKategorie();
    vsetkyKategorie = kategorieData.map((k) => k['nazov'] as String).toList();
    // Overím platnosť aktuálne zvolenej kategórie
    if (selectedKategoria != null &&
        !vsetkyKategorie.contains(selectedKategoria)) {
      selectedKategoria = null;
    }
    notifyListeners(); // Notifikujem o zmene zoznamu kategórií
  }

  // Metóda volaná z UI na obnovenie kategórií (napr. po pridaní novej cez FunctionsProvider)
  Future<void> refreshKategorie() async {
    await _loadKategorieFromDb();
  }

  // --- Metódy na modifikáciu stavu ---

  void setSelectedKategoria(String? value) {
    if (selectedKategoria != value) {
      selectedKategoria = value;
      notifyListeners();
    }
  }

  void toggleStepMode(bool value) {
    if (isStepMode != value) {
      isStepMode = value;
      if (isStepMode) {
        _textToSteps();
      } else {
        _stepsToText();
      }
      notifyListeners();
    }
  }

  void _textToSteps() {
    steps = [];
    final lines =
        postupController.text
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
    for (var i = 0; i < lines.length; i++) {
      final textWithoutNumber = lines[i].replaceFirst(
        RegExp(r'^\d+\s*[-.)]?\s*'),
        '',
      );
      steps.add({'number': i + 1, 'text': textWithoutNumber});
    }
    // notifyListeners(); // Volá sa v toggleStepMode
  }

  void _stepsToText() {
    postupController.text = steps
        .map((step) => '${step['number']} - ${step['text']}')
        .join('\n');
    // notifyListeners(); // Volá sa v toggleStepMode
  }

  String _stepsToTextForSave() {
    return steps
        .map((step) => '${step['number']} - ${step['text']}')
        .join('\n');
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImages.add(File(pickedFile.path));
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  void addIngredient(String name, double? quantity, String unit) {
    String ingredientString = name.trim();
    if (quantity != null) {
      String formattedMnozstvo =
          quantity == quantity.toInt()
              ? quantity.toInt().toString()
              : quantity.toString();
      ingredientString += ' $formattedMnozstvo';
    }
    if (unit != '...') {
      ingredientString += ' $unit';
    }
    ingrediencie.add(ingredientString.trim());
    notifyListeners();
  }

  void updateIngredient(
    String originalIngredient,
    String name,
    double? quantity,
    String unit,
  ) {
    String ingredientString = name.trim();
    if (quantity != null) {
      String formattedMnozstvo =
          quantity == quantity.toInt()
              ? quantity.toInt().toString()
              : quantity.toString();
      ingredientString += ' $formattedMnozstvo';
    }
    if (unit != '...') {
      ingredientString += ' $unit';
    }
    final index = ingrediencie.indexOf(originalIngredient);
    if (index != -1) {
      ingrediencie[index] = ingredientString.trim();
    } else {
      ingrediencie.add(ingredientString.trim()); // Fallback
    }
    notifyListeners();
  }

  void removeIngredient(String ingredient) {
    ingrediencie.remove(ingredient);
    notifyListeners();
  }

  void addStep(String text) {
    steps.add({'number': steps.length + 1, 'text': text.trim()});
    notifyListeners();
  }

  void editStep(int index, String newText) {
    if (index >= 0 && index < steps.length) {
      steps[index]['text'] = newText.trim();
      notifyListeners();
    }
  }

  void removeStep(int index) {
    if (index >= 0 && index < steps.length) {
      steps.removeAt(index);
      // Prečíslujem
      for (var i = 0; i < steps.length; i++) {
        steps[i]['number'] = i + 1;
      }
      notifyListeners();
    }
  }

  // Uložím upravený recept
  Future<Map<String, dynamic>?> saveChanges() async {
    // Vráti upravený recept alebo null pri chybe
    if (nazovController.text.trim().isEmpty) {
      // Tu by sme mohli vrátiť chybovú správu alebo null
      print("Názov je povinný!");
      return null;
    }

    isLoading = true;
    notifyListeners(); // Zobrazí indikátor načítania

    final postupText =
        isStepMode ? _stepsToTextForSave() : postupController.text;
    String obrazkyJsonString;
    try {
      obrazkyJsonString = jsonEncode(
        selectedImages.map((i) => i.path).toList(),
      );
    } catch (e) {
      print("Chyba JSON obrázky: $e");
      obrazkyJsonString = '[]';
    }

    final updatedRecept = {
      'id': _initialReceptData['id'], // Použijem pôvodné ID
      'nazov': nazovController.text.trim(),
      'kategoria': selectedKategoria ?? _initialReceptData['kategoria'] ?? '',
      'ingrediencie': ingrediencie.join(', '),
      'postup': postupText,
      'poznamky': poznamkyController.text,
      'obrazky': obrazkyJsonString,
      'isFavorite': _initialReceptData['isFavorite'] ?? 0, // Zachovám pôvodné
    };

    try {
      // Zavolám update metódu na *globálnom* ReceptProvideri
      await _receptProvider.updateRecept(updatedRecept);
      isLoading = false;
      notifyListeners(); // Skryjem indikátor a notifikujem o úspechu (ak UI reaguje)
      return updatedRecept; // Vrátim úspešne uložené dáta
    } catch (e) {
      print("Chyba pri aktualizácii receptu v provideri: $e");
      isLoading = false;
      notifyListeners(); // Skryjem indikátor
      return null; // Vrátim null pri chybe
    }
  }

  // Uvoľním zdroje controllerov, keď sa notifier už nepoužíva
  @override
  void dispose() {
    nazovController.dispose();
    postupController.dispose();
    poznamkyController.dispose();
    super.dispose();
  }
}

// === State trieda pre UpravitRecept (teraz používa Notifier) ===
class _UpravitReceptState extends State<UpravitRecept>
    with WidgetsBindingObserver {
  // === Lokálny stav UI ===
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarScrolled = false;
  UniqueKey _scaffoldKey = UniqueKey();

  // === Inštancia Notifiera ===
  // Vytvorím inštanciu notifiera pre stav formulára
  // Je 'late final', lebo potrebujem context pre Provider.of v initState
  late final EditReceptNotifier _formStateNotifier;

  // === Provider pre pomocné funkcie ===
  // Môže zostať tu, ak ho nepotrebuje notifier priamo
  late final FunctionsProvider _functionsProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Získam globálny ReceptProvider a FunctionsProvider
    final receptProvider = Provider.of<ReceptProvider>(context, listen: false);
    _functionsProvider = Provider.of<FunctionsProvider>(context, listen: false);

    // Vytvorím notifier a odovzdám mu závislosti
    _formStateNotifier = EditReceptNotifier(
      initialData: widget.recept, // Pôvodné dáta receptu
      dbHelper: DatabaseHelper.instance, // Inštancia DB Helpera
      receptProvider: receptProvider, // Inštancia globálneho providera
    );

    // Pridám listener na scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Dôležité: Uvoľním aj notifier!
    _formStateNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resetovanie UI po návrate do appky zostáva rovnaké
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // Loading flag je teraz v notifieri, ale môžeme ho ovládať aj tu pre UI efekt
        // _formStateNotifier.isLoading = true; // Prípadne
      }
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _scaffoldKey = UniqueKey();
          });
        }
      });
    }
  }

  // Handler pre scroll (zostáva rovnaký)
  void _onScroll() {
    final bool needsSolidBackground = _scrollController.offset > 10;
    if (needsSolidBackground != _isAppBarScrolled && mounted) {
      setState(() {
        _isAppBarScrolled = needsSolidBackground;
      });
    }
  }

  // --- Metóda na uloženie volá metódu notifiera ---
  Future<void> _ulozZmeny() async {
    // Zavolám metódu na uloženie v notifieri
    final Map<String, dynamic>? vysledok =
        await _formStateNotifier.saveChanges();

    if (!mounted) return; // Kontrola mounted po await

    if (vysledok != null) {
      // Uloženie bolo úspešné
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recept aktualizovaný!')));
      // Vrátim sa späť a pošlem aktualizované dáta
      Navigator.pop(context, vysledok);
    } else {
      // Nastala chyba pri ukladaní (notifier vrátil null)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nastala chyba pri ukladaní receptu.')),
      );
    }
  }

  // --- Build metóda ---
  @override
  Widget build(BuildContext context) {
    // Použijem Consumer na počúvanie zmien v EditReceptNotifier
    return ChangeNotifierProvider.value(
      // Použijem .value, lebo notifier vytváram v initState
      value: _formStateNotifier,
      child: Consumer<EditReceptNotifier>(
        // Consumer sleduje zmeny
        builder: (context, formState, child) {
          // formState je naša inštancia EditReceptNotifier
          // Teraz celé UI čerpá dáta a volá akcie cez 'formState'
          return Scaffold(
            backgroundColor: Colors.grey[100],
            body: Stack(
              children: [
                Scaffold(
                  key: _scaffoldKey,
                  extendBodyBehindAppBar: true,
                  appBar: PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarHeight + 20),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: AppBar(
                        title: Text(
                          'Upraviť recept',
                          style: TextStyle(
                            color:
                                _isAppBarScrolled
                                    ? Colors.grey[800]
                                    : Colors.black,
                          ),
                        ),
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color:
                                _isAppBarScrolled
                                    ? Colors.grey[800]
                                    : Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        backgroundColor:
                            _isAppBarScrolled
                                ? Colors.grey[200]
                                : Colors.transparent,
                        elevation: _isAppBarScrolled ? 1.0 : 0.0,
                        foregroundColor: Colors.grey[800],
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.blue),
                            tooltip: 'Uložiť zmeny',
                            onPressed: formState.isLoading ? null : _ulozZmeny,
                          ), // Použijem isLoading z notifiera
                        ],
                      ),
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  body: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top:
                          (kToolbarHeight + 20) +
                          MediaQuery.of(context).padding.top,
                      bottom: kToolbarHeight + 40,
                    ),
                    child: Column(
                      children: [
                        // Sekcia Obrázky (číta dáta z formState)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: formState.selectedImages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == formState.selectedImages.length) {
                                return GestureDetector(
                                  onTap:
                                      formState.isLoading
                                          ? null
                                          : formState.pickImage,
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        242,
                                        247,
                                        251,
                                        1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.4),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
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
                                return Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: FileImage(
                                            formState.selectedImages[index],
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => formState.removeImage(index),
                                      child: Container(
                                        margin: const EdgeInsets.all(4),
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sekcia Názov (používa controller z formState)
                        _buildFormFieldContainer(
                          title: 'Názov receptu',
                          child: TextFormField(
                            controller: formState.nazovController,
                            decoration: const InputDecoration(
                              hintText: 'Zadajte názov...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Povinné!'
                                        : null,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sekcia Kategória (číta dáta a volá metódu z formState)
                        _buildFormFieldContainer(
                          title: 'Kategória',
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: formState.selectedKategoria,
                                    hint: const Text('Vyberte kategóriu'),
                                    isExpanded: true,
                                    onChanged:
                                        formState.isLoading
                                            ? null
                                            : (v) => formState
                                                .setSelectedKategoria(v),
                                    items:
                                        formState.vsetkyKategorie
                                            .map(
                                              (val) => DropdownMenuItem<String>(
                                                value: val,
                                                child: Text(val),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.blue),
                                tooltip: 'Pridať kategóriu',
                                onPressed:
                                    formState.isLoading
                                        ? null
                                        : () {
                                          if (!mounted) return;
                                          _functionsProvider
                                              .openKategoriaDialog(
                                                context,
                                                formState.refreshKategorie,
                                              );
                                        },
                              ), // Volám refreshKategorie na notifieri
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sekcia Ingrediencie (číta dáta a volá metódy z formState)
                        _buildFormFieldContainer(
                          title: 'Ingrediencie',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: formState.ingrediencie.length,
                                itemBuilder: (context, index) {
                                  final ing = formState.ingrediencie[index];
                                  return ListTile(
                                    title: Text(ing),
                                    contentPadding: EdgeInsets.zero,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          tooltip: 'Upraviť',
                                          onPressed:
                                              formState.isLoading
                                                  ? null
                                                  : () =>
                                                      _openUpdateIngrediencieDialog(
                                                        context,
                                                        formState,
                                                        ing,
                                                      ),
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
                                            size: 20,
                                          ),
                                          tooltip: 'Odstrániť',
                                          onPressed:
                                              formState.isLoading
                                                  ? null
                                                  : () =>
                                                      _showDeleteConfirmationDialog(
                                                        context,
                                                        formState,
                                                        ing,
                                                      ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                title: const Text('Pridať ingredienciu'),
                                contentPadding: EdgeInsets.zero,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Pridať',
                                  onPressed:
                                      formState.isLoading
                                          ? null
                                          : () => _openIngrediencieDialog(
                                            context,
                                            formState,
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sekcia Postup (číta dáta a volá metódy z formState)
                        _buildFormFieldContainer(
                          title: '',
                          titleWidget: Row(
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
                                    value: formState.isStepMode,
                                    onChanged:
                                        formState.isLoading
                                            ? null
                                            : (v) =>
                                                formState.toggleStepMode(v),
                                    activeColor: Colors.blue,
                                    inactiveThumbColor: const Color.fromARGB(
                                      255,
                                      88,
                                      88,
                                      88,
                                    ),
                                    inactiveTrackColor: Colors.grey[300],
                                    activeTrackColor: Colors.blue.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          child:
                              formState.isStepMode
                                  ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStepsListScrollableArea(formState),
                                      const SizedBox(height: 5),
                                      ListTile(
                                        title: const Text('Pridať krok'),
                                        contentPadding: EdgeInsets.zero,
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            color: Colors.blue,
                                          ),
                                          tooltip: 'Pridať',
                                          onPressed:
                                              formState.isLoading
                                                  ? null
                                                  : () => _addStepDialog(
                                                    context,
                                                    formState,
                                                  ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : _buildPostupTextField(
                                    formState,
                                  ), // Zobrazenie jedného poľa
                        ),
                        const SizedBox(height: 20),

                        // Sekcia Poznámky (používa controller z formState)
                        _buildFormFieldContainer(
                          title: 'Poznámky',
                          child: TextFormField(
                            controller: formState.poznamkyController,
                            decoration: const InputDecoration(
                              hintText: 'Pridajte poznámky...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Indikátor načítania (číta stav z formState)
                if (formState.isLoading)
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
        },
      ),
    );
  }

  // --- Pomocné metódy pre Build (teraz prijímajú formState) ---

  // Vytvorí štýlovaný kontajner pre sekciu formulára
  Widget _buildFormFieldContainer({
    required String title,
    Widget? titleWidget,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(242, 247, 251, 1.0),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget ??
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // Vytvorí VÝŠKOVO OBMEDZENÚ scrollovateľnú oblasť pre kroky
  Widget _buildStepsListScrollableArea(EditReceptNotifier formState) {
    // Prijíma notifier
    return Container(
      constraints: const BoxConstraints(maxHeight: 200.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(5),
      ),
      child:
          formState.steps.isEmpty
              ? const Center(
                child: Text(
                  "Zatiaľ žiadne kroky.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                itemCount: formState.steps.length,
                itemBuilder: (context, index) {
                  if (index >= formState.steps.length)
                    return const SizedBox.shrink();
                  final step = formState.steps[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    leading: Text(
                      '${step['number']} -',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: Text(step['text']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          tooltip: 'Upraviť',
                          onPressed:
                              formState.isLoading
                                  ? null
                                  : () => _editStepDialog(
                                    context,
                                    formState,
                                    index,
                                  ),
                        ), // Volá upravený dialóg
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color.fromARGB(255, 88, 88, 88),
                            size: 20,
                          ),
                          tooltip: 'Odstrániť',
                          onPressed:
                              formState.isLoading
                                  ? null
                                  : () => formState.removeStep(index),
                        ), // Volá metódu notifiera
                      ],
                    ),
                  );
                },
              ),
    );
  }

  // Vytvorí jedno textové pole pre postup
  Widget _buildPostupTextField(EditReceptNotifier formState) {
    // Prijíma notifier
    return TextFormField(
      controller: formState.postupController, // Používa controller z notifiera
      decoration: const InputDecoration(
        hintText: 'Napíšte postup prípravy...',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: 5,
      keyboardType: TextInputType.multiline,
    );
  }

  // --- Dialógy (teraz prijímajú Notifier) ---

  // Potvrdenie zmazania ingrediencie
  void _showDeleteConfirmationDialog(
    BuildContext context,
    EditReceptNotifier formState,
    String ingrediencia,
  ) {
    showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(242, 247, 251, 1.0),
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
            'Naozaj odstrániť?',
            style: TextStyle(color: Color.fromARGB(255, 43, 40, 40)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text(
                'Zrušiť',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            TextButton(
              onPressed: () {
                formState.removeIngredient(ingrediencia);
                Navigator.pop(c);
              },
              child: const Text(
                'Odstrániť',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Pridanie novej ingrediencie
  void _openIngrediencieDialog(
    BuildContext context,
    EditReceptNotifier formState,
  ) {
    String localSelectedUnit = '...'; // Lokálna premenná pre dialóg
    final nc = TextEditingController();
    final qc = TextEditingController();
    String? tempIngredientName; // Pre validáciu tlačidla

    showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color.fromRGBO(242, 247, 251, 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text(
                "Pridať ing.",
                style: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nc,
                    onChanged: (v) {
                      tempIngredientName = v;
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Názov ingrediencie',
                      /*...*/ labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: qc,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Množstvo (vol.)',
                      /*...*/ labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: localSelectedUnit,
                    onChanged: (v) {
                      setDialogState(() => localSelectedUnit = v!);
                    },
                    items:
                        formState.units
                            .map(
                              (u) => DropdownMenuItem<String>(
                                value: u,
                                child: Text(
                                  u,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 43, 40, 40),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text(
                    'Zrušiť',
                    style: TextStyle(color: Color.fromARGB(255, 90, 29, 29)),
                  ),
                ),
                TextButton(
                  onPressed:
                      tempIngredientName != null &&
                              tempIngredientName!.trim().isNotEmpty
                          ? () {
                            final n = nc.text.trim();
                            final m = double.tryParse(
                              qc.text.replaceAll(',', '.'),
                            );
                            formState.addIngredient(n, m, localSelectedUnit);
                            Navigator.pop(c);
                          }
                          : null,
                  child: Text(
                    'Pridať',
                    style: TextStyle(
                      color:
                          tempIngredientName != null &&
                                  tempIngredientName!.trim().isNotEmpty
                              ? const Color.fromARGB(255, 0, 0, 0)
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nc.dispose();
      qc.dispose();
    });
  }

  // Úprava existujúcej ingrediencie
  void _openUpdateIngrediencieDialog(
    BuildContext context,
    EditReceptNotifier formState,
    String ingrediencia,
  ) {
    String pN = '';
    String? pMS;
    String? pJ;
    final unitsP = formState.units
        .where((u) => u != '...')
        .map((u) => RegExp.escape(u))
        .join('|');
    final rQUs = RegExp(
      r'^(.*?)\s+(\d+(?:[.,]\d+)?)\s*(' + unitsP + r')?$',
      caseSensitive: false,
    );
    final rQO = RegExp(r'^(.*?)\s+(\d+(?:[.,]\d+)?)$');
    final mWU = rQUs.firstMatch(ingrediencia.trim());
    final mQO = rQO.firstMatch(ingrediencia.trim());
    if (mWU != null) {
      pN = mWU.group(1)?.trim() ?? '';
      pMS = mWU.group(2)?.replaceAll(',', '.');
      pJ = mWU.group(3);
      if (pJ != null) {
        pJ = formState.units.firstWhere(
          (u) => u.toLowerCase() == pJ!.toLowerCase(),
          orElse: () => '...',
        );
      }
    } else if (mQO != null) {
      pN = mQO.group(1)?.trim() ?? '';
      pMS = mQO.group(2)?.replaceAll(',', '.');
      pJ = null;
    } else {
      pN = ingrediencia.trim();
      pMS = null;
      pJ = null;
    }
    String tempSelectedUnit =
        (pJ != null && formState.units.contains(pJ)) ? pJ : '...';
    String? tempIngredientName = pN;
    final nc = TextEditingController(text: pN);
    final qc = TextEditingController(text: pMS ?? '');
    showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            return AlertDialog(
              backgroundColor: const Color.fromRGBO(242, 247, 251, 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text(
                "Upraviť ing.",
                style: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nc,
                    onChanged: (v) {
                      tempIngredientName = v;
                      setS(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Názov',
                      labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: qc,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => setS(() {}),
                    decoration: InputDecoration(
                      labelText: 'Množstvo (vol.)',
                      labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: tempSelectedUnit,
                    onChanged: (v) {
                      setS(() => tempSelectedUnit = v!);
                    },
                    items:
                        formState.units
                            .map(
                              (u) => DropdownMenuItem<String>(
                                value: u,
                                child: Text(
                                  u,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 43, 40, 40),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text(
                    'Zrušiť',
                    style: TextStyle(color: Color.fromARGB(255, 90, 29, 29)),
                  ),
                ),
                TextButton(
                  onPressed:
                      tempIngredientName != null &&
                              tempIngredientName!.trim().isNotEmpty
                          ? () {
                            final nV = nc.text.trim();
                            final mV = double.tryParse(
                              qc.text.replaceAll(',', '.'),
                            );
                            final uV = tempSelectedUnit;
                            formState.updateIngredient(
                              ingrediencia,
                              nV,
                              mV,
                              uV,
                            );
                            Navigator.pop(c);
                          }
                          : null,
                  child: Text(
                    'Uložiť',
                    style: TextStyle(
                      color:
                          tempIngredientName != null &&
                                  tempIngredientName!.trim().isNotEmpty
                              ? const Color.fromARGB(255, 0, 0, 0)
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nc.dispose();
      qc.dispose();
    });
  }

  // Pridanie nového kroku (volá metódu notifiera)
  void _addStepDialog(BuildContext context, EditReceptNotifier formState) {
    final stepController = TextEditingController();
    showDialog<String?>(
      // Návratový typ je teraz text kroku
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(242, 247, 251, 1.0),
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
              controller: stepController,
              decoration: InputDecoration(
                labelText: 'Text kroku',
                /*...*/ labelStyle: const TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
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
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                'Zrušiť',
                style: TextStyle(color: Color.fromARGB(255, 90, 29, 29)),
              ),
            ),
            TextButton(
              onPressed: () {
                final text = stepController.text.trim();
                Navigator.pop(
                  context,
                  text.isNotEmpty ? text : null,
                ); // Vrátim text alebo null
              },
              child: const Text(
                'Pridať',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
          ],
        );
      },
    ).then((stepText) {
      stepController.dispose();
      if (stepText != null && mounted) {
        formState.addStep(
          stepText,
        ); // Zavolám metódu notifiera na pridanie kroku
      }
    });
  }

  // Úprava existujúceho kroku (volá metódu notifiera)
  void _editStepDialog(
    BuildContext context,
    EditReceptNotifier formState,
    int index,
  ) {
    final step = formState.steps[index];
    final stepController = TextEditingController(text: step['text']);
    showDialog<String?>(
      // Návratový typ je upravený text
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(242, 247, 251, 1.0),
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
              controller: stepController,
              decoration: InputDecoration(
                labelText: 'Text kroku',
                /*...*/ labelStyle: const TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
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
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                'Zrušiť',
                style: TextStyle(color: Color.fromARGB(255, 90, 29, 29)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  stepController.text,
                ); // Vrátim upravený text
              },
              child: const Text(
                'Uložiť',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
          ],
        );
      },
    ).then((newText) {
      stepController.dispose();
      if (newText != null && mounted) {
        formState.editStep(
          index,
          newText,
        ); // Zavolám metódu notifiera na úpravu
      }
    });
  }
} // Koniec _UpravitReceptState
