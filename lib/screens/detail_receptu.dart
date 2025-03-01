import 'package:flutter/material.dart';
import 'dart:io'; // For File and FileImage
import 'upravit_recept.dart'; // Nová obrazovka pre úpravu receptu
import '../providers/recept_provider.dart'; // Import your ReceptProvider
import 'package:provider/provider.dart'; // Import Provider package
import 'dart:convert'; // For jsonDecode

class DetailReceptu extends StatefulWidget {
  final Map<String, dynamic> recept;

  const DetailReceptu({super.key, required this.recept});

  @override
  State<DetailReceptu> createState() => _DetailReceptuState();
}

class _DetailReceptuState extends State<DetailReceptu> {
  // Function to show a confirmation dialog before deleting the recipe
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Potvrdenie vymazania'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Naozaj chcete vymazať tento recept?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Zrušiť'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Vymazať', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Delete the recipe
                final receptProvider = Provider.of<ReceptProvider>(context, listen: false);
                await receptProvider.vymazatRecept(widget.recept['id']);

                if (!mounted) return;

                // Show a snackbar to confirm deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recept bol vymazaný!')),
                );

                // Navigate back to the previous screen
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if the postup text contains step numbers
    final postupText = widget.recept['postup'];
    final isStepByStep = postupText.contains(RegExp(r'^\d+ - '));

    // Parse the obrazky field as a list of image paths
    List<String> imagePaths = [];
    if (widget.recept['obrazky'] != null) {
      try {
        // Decode the JSON string if necessary
        final dynamic obrazky = widget.recept['obrazky'];
        if (obrazky is String) {
          imagePaths = (jsonDecode(obrazky) as List<dynamic>).cast<String>();
        } else if (obrazky is List<dynamic>) {
          imagePaths = obrazky.cast<String>();
        }
      } catch (e) {
        print('Error parsing obrazky: $e');
      }
    }

    // Filter out invalid paths
    imagePaths = imagePaths.where((path) {
      final file = File(path);
      return file.existsSync(); // Check if the file exists
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail receptu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpravitRecept(recept: widget.recept),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () {
              _showDeleteConfirmationDialog(context); // Show confirmation dialog
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel for Recipe Images using PageView (only if there are images)
            if (imagePaths.isNotEmpty)
              SizedBox(
                height: 200, // Height of the carousel
                child: PageView.builder(
                  itemCount: imagePaths.length,
                  itemBuilder: (context, index) {
                    final imagePath = imagePaths[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(File(imagePath)), // Load image from file
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.recept['nazov'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Kategória: ${widget.recept['kategoria'] ?? 'Bez kategórie'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ingrediencie:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.recept['ingrediencie'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Postup:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (isStepByStep)
              ...postupText.split('\n').map((step) {
                return Text(
                  step,
                  style: const TextStyle(fontSize: 16),
                );
              }).toList()
            else
              Text(
                postupText,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 20),
            const Text(
              'Poznámky:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.recept['poznamky'],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}