import 'package:flutter/material.dart';
import '../models/awareness_model.dart';

class AdminAwarenessManagementScreen
    extends StatefulWidget {
  const AdminAwarenessManagementScreen({super.key});

  @override
  State<AdminAwarenessManagementScreen>
      createState() =>
          _AdminAwarenessManagementScreenState();
}

class _AdminAwarenessManagementScreenState
    extends State<AdminAwarenessManagementScreen> {

  final titleController = TextEditingController();
  final descriptionController =
      TextEditingController();
  final categoryController =
      TextEditingController();
  final imageController =
      TextEditingController();

  final Color deepBlue =
      const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Awareness Management'),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration:
                  const InputDecoration(
                      labelText: 'Title'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: categoryController,
              decoration:
                  const InputDecoration(
                      labelText:
                          'Category'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: imageController,
              decoration:
                  const InputDecoration(
                      labelText:
                          'Image Path (assets/images/...)'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller:
                  descriptionController,
              maxLines: 4,
              decoration:
                  const InputDecoration(
                      labelText:
                          'Description'),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width:
                  double.infinity,
              child: ElevatedButton(
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      deepBlue,
                ),
                onPressed:
                    addContent,
                child:
                    const Text(
                  'Add Content',
                  style:
                      TextStyle(
                          color:
                              Colors
                                  .white),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            Expanded(
              child:
                  ListView.builder(
                itemCount:
                    AwarenessData
                        .contents
                        .length,
                itemBuilder:
                    (context, index) {
                  final content =
                      AwarenessData
                          .contents[index];

                  return Card(
                    child:
                        ListTile(
                      title: Text(
                          content.title),
                      subtitle: Text(
                          content.category),
                      trailing:
                          IconButton(
                        icon:
                            const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed:
                            () {
                          setState(() {
                            AwarenessData
                                .contents
                                .removeAt(
                                    index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void addContent() {
    if (titleController.text.isEmpty ||
        descriptionController
            .text.isEmpty ||
        categoryController
            .text.isEmpty ||
        imageController.text
            .isEmpty) {
      return;
    }

    setState(() {
      AwarenessData.contents.add(
        AwarenessContent(
          title:
              titleController.text,
          description:
              descriptionController
                  .text,
          category:
              categoryController
                  .text,
          imagePath:
              imageController.text,
        ),
      );
    });

    titleController.clear();
    descriptionController.clear();
    categoryController.clear();
    imageController.clear();
  }
}