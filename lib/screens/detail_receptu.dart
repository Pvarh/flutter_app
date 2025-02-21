import 'package:flutter/material.dart';
import 'upravit_recept.dart'; // Nová obrazovka pre úpravu receptu
import '../providers/recept_provider.dart'; // Import your ReceptProvider
import 'package:provider/provider.dart'; // Import Provider package

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
            icon: const Icon(Icons.delete, color: Colors.red),
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
            Text(
              widget.recept['postup'],
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