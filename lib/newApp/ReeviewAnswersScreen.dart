import 'package:flutter/material.dart';
import 'package:mittsure/newApp/hointervention.dart';

class ReviewAnswersScreen extends StatefulWidget {
  final List<Map<dynamic, dynamic>> answers;
  final dynamic payload;
  final category;
  final interested;
  final visit;

  const ReviewAnswersScreen({
    super.key,
    required this.visit,
    required this.answers,
    required this.payload,
    required this.category,
    required this.interested
  });

  @override
  State<ReviewAnswersScreen> createState() => _ReviewAnswersScreenState();
}

class _ReviewAnswersScreenState extends State<ReviewAnswersScreen> {
  void submit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HoInterventionScreen(
          payload: widget.payload,
          answers: widget.answers,
          interested: widget.interested,
          visit: widget.visit,
          meetingHappen: "yes",
        ),
      ),
    );
  }

   getCategoryName(id) {
    var b = widget.category.where((element) => element['id'].toString() == id).toList();
    return b.isEmpty ? "" : b[0]['name'].toString().toUpperCase();
  }

  Map<String, List<Map<dynamic, dynamic>>> groupAnswersByCategory() {
    final Map<String, List<Map<dynamic, dynamic>>> grouped = {};
    for (var answer in widget.answers) {
      final category = answer['category'] ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(answer);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedAnswers = groupAnswersByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Review Answers',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: groupedAnswers.entries.map((entry) {
                  final category = entry.key;
                  final answers = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          getCategoryName(category),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ),
                      ...answers.map((answer) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin:
                              const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: answer.entries.map((entry) {
                                if (entry.key == 'category' ||
                                    entry.key == 'title') {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${entry.key}: ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "${entry.value}",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submit,
                icon: const Icon(Icons.check_circle_outline,color: Colors.green,),
                label: const Text("Proceed",style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
