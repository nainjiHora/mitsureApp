import 'package:flutter/material.dart';
import 'package:mittsure/newApp/hointervention.dart';

class ReviewAnswersScreen extends StatefulWidget {
  final List<Map<dynamic, dynamic>> answers;
  final dynamic payload;

  const ReviewAnswersScreen({
    super.key,
    required this.answers,
    required this.payload,
  });

  @override
  State<ReviewAnswersScreen> createState() => _ReviewAnswersScreenState();
}

class _ReviewAnswersScreenState extends State<ReviewAnswersScreen> {
  void submit() {
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HoInterventionScreen(payload: widget.payload,answers:widget.answers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(widget.payload);
    print(widget.answers);
    print("llolo");

    return Scaffold(
      appBar: AppBar(
        title: Text("Review Answers"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.answers.length,
                itemBuilder: (context, index) {
                  final answer = widget.answers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: answer.entries.map((entry) {
                          if (entry.key == 'category' || entry.key == 'title') {
                            return SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              "${entry.key}: ${entry.value}",
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submit,
                icon: Icon(Icons.save),
                label: Text("Submit"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
