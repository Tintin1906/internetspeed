import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InternetSpeedScreen extends StatefulWidget {
  @override
  _InternetSpeedScreenState createState() => _InternetSpeedScreenState();
}

class _InternetSpeedScreenState extends State<InternetSpeedScreen> {
  final CollectionReference speeds = FirebaseFirestore.instance.collection('InternetSpeed');

  void _addSpeed() {
    TextEditingController nameController = TextEditingController();
    TextEditingController providerController = TextEditingController();
    TextEditingController speedController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Internet Speed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: 'User Name')),
                  TextField(controller: providerController, decoration: InputDecoration(labelText: 'Provider Name')),
                  TextField(controller: speedController, decoration: InputDecoration(labelText: 'Download Speed (Mbps)'), keyboardType: TextInputType.number),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    try {
                      final double downloadSpeed = double.parse(speedController.text);
                      await speeds.add({
                        'userName': nameController.text,
                        'provider': providerController.text,
                        'downloadSpeed': downloadSpeed,
                      });
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add speed: $e')),
                      );
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editSpeed(DocumentSnapshot doc) {
    TextEditingController providerController = TextEditingController(text: doc['provider']);
    TextEditingController speedController = TextEditingController(text: doc['downloadSpeed'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Internet Speed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: providerController, decoration: InputDecoration(labelText: 'Provider Name')),
                  TextField(controller: speedController, decoration: InputDecoration(labelText: 'Download Speed (Mbps)'), keyboardType: TextInputType.number),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                TextButton(
                  onPressed: () {
                    try {
                      final double downloadSpeed = double.parse(speedController.text);
                      speeds.doc(doc.id).update({
                        'provider': providerController.text,
                        'downloadSpeed': downloadSpeed,
                      });
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update speed: $e')),
                      );
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSpeed(String id) {
    speeds.doc(id).delete();
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                _deleteSpeed(id);
                Navigator.pop(context);
              },
              child: Text('Delete'),
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
        title: Text('Internet Speed Records',
        style: TextStyle(color:const Color(0xFFFBF8EF)),),        
        backgroundColor: const Color(0xFF80CBC4), 
      ),
      backgroundColor: const Color(0xFFFBF8EF),
      body: Expanded(
        child: StreamBuilder(
          stream: speeds.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error fetching data.'));
            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No data available.'));
            }

            return ListView(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>?;

                
                if (data == null || !data.containsKey('downloadSpeed') || !data.containsKey('provider') || !data.containsKey('userName')) {
                  return SizedBox.shrink();
                }

                bool isEditHovered = false;
                bool isDeleteHovered = false;

                return StatefulBuilder(
                  builder: (context, setState) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color(0x66B4EBE6), 
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListTile(
                        title: Text('${data['userName']}'),
                        subtitle: Text('Download Speed: ${data['downloadSpeed']} Mbps'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MouseRegion(
                              onEnter: (_) => setState(() => isEditHovered = true),
                              onExit: (_) => setState(() => isEditHovered = false),
                              child: IconButton(
                                icon: Icon(Icons.edit, color: isEditHovered ? Colors.blue : Colors.grey),
                                onPressed: () => _editSpeed(doc),
                              ),
                            ),
                            MouseRegion(
                              onEnter: (_) => setState(() => isDeleteHovered = true),
                              onExit: (_) => setState(() => isDeleteHovered = false),
                              child: IconButton(
                                icon: Icon(Icons.delete, color: isDeleteHovered ? Colors.red : Colors.grey),
                                onPressed: () => _confirmDelete(doc.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), 
        child: FloatingActionButton.extended(
          onPressed: _addSpeed,
          label: Text(
            'New speed',
            style: TextStyle(color: Colors.white), 
          ),
          icon: Icon(Icons.add, color: Colors.white), 
          backgroundColor: const Color(0xFFFFB433), 
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}