import 'package:flutter/material.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class ProductCategoryInput extends StatefulWidget {
  const ProductCategoryInput({super.key});

  @override
  State<ProductCategoryInput> createState() => _ProductCategoryInputState();
}

class _ProductCategoryInputState extends State<ProductCategoryInput> {
  List<Map<dynamic, dynamic>> answers = [{}];
  List<dynamic> categories = [];
  List<String?> selectedCategories = [];
  List<List<dynamic>> questionList = [[]];
  List<dynamic> questions = [];
  String? interested;
  int selectedindex = 0;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  fetchCategories() async {
    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getQuestionCategory',
        body: {},
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          categories = data;
        });
      }
    } catch (error) {
      print("Error fetching categories: $error");
    }
  }

  getQuestions(value) async {
    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getQuestionWithOption',
        body: {"category_id": value},
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          questions = data;
          questionList[selectedindex] = [];
          answers[selectedindex] = {'category': value};
          questionList[selectedindex].add(data[0]);
        });
      }
    } catch (error) {
      print("Error fetching questions: $error");
    }
  }

  getCategoryName(id){
    
   var b= categories.where((element) => element['id'].toString()==id).toList();
   print(categories);
   return b==null||b.length==0?"":b[0]['name'];

  }

  void nextQuestion(int nextQuestionId) {
    print(nextQuestionId);
    final nextQ = questions.firstWhere(
      (q) => q['question_id'] == nextQuestionId,
      orElse: () => null,
    );
    print(nextQ);
    if (nextQ != null &&
        !questionList[selectedindex]
            .any((q) => q['question_id'] == nextQ['question_id'])) {
      setState(() {
        questionList[selectedindex].add(nextQ);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainMenuScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Product Explained"),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: _buildDropdown(
                      "School Interested",
                      [
                        {"name": 'Yes'},
                        {"name": 'No'}
                      ],
                      "name",
                      "name",
                      interested,
                      (value) {
                        setState(() {
                          interested = value;
                        });
                      },
                    ),
                  ),
                  if (interested == 'Yes')
                    ...List.generate(questionList.length, (index) {
                      return index == selectedindex
                          ? Column(
                              children: [
                                Card(
                                  child: _buildDropdown(
                                    "Select Product Category",
                                    categories,
                                    "id",
                                    "name",
                                    selectedCategories.length > index
                                        ? selectedCategories[index]
                                        : null,
                                    (value) {
                                      if (selectedCategories.length <= index) {
                                        selectedCategories.add(value);
                                      } else {
                                        selectedCategories[index] = value;
                                      }
                                      selectedindex = index;
                                      getQuestions(value);
                                    },
                                  ),
                                ),
                                ...questionList[index].map((q) => Card(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: _buildQuestionWidget(q, index),
                                      ),
                                    )),
                                if (questionList[index].isNotEmpty &&
                                    questionList[index].last['final'] == 1)
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            answers.add({});
                                            questionList.add([]);
                                            selectedCategories.add(null);
                                            selectedindex =
                                                questionList.length - 1;
                                          });
                                        },
                                        icon: Icon(Icons.add),
                                        label: Text("Add more"),
                                      ),
                                    ],
                                  ),
                                Divider()
                              ],
                            )
                          : Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getCategoryName(selectedCategories[index]) ?? "",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 25),
                                        ),
                                        IconButton(onPressed: (){setState(() {
                                          selectedindex=index;
                                        });}, icon: Icon(Icons.remove_red_eye))
                                      ],
                                    ),
                                    Text(
                                      answers[selectedindex]['title'],
                                      style: TextStyle(fontSize: 20),
                                    )
                                  ],
                                ),
                              ),
                            );
                    }),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                print("Review Answers: $answers");
              },
              icon: Icon(Icons.check),
              label: Text("Review"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(dynamic question, int index) {
    final type = question['question_type'];
    final options = question['options'] ?? [];

    switch (type) {
      case 'radio':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question['question'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...options.map<Widget>((opt) {
              return RadioListTile(
                title: Text(opt['option']),
                value: opt['option_id'].toString(),
                groupValue: answers[index][question['question_id']]?.toString(),
                onChanged: (value) {
                  setState(() {
                    answers[index][question['question_id']] = value;
                    if (question["title"] == 1 || question["title"] == "1") {
                      answers[index]['title'] = value;
                    }
                  });
                  nextQuestion(opt['next_question_id']);
                },
              );
            }).toList(),
          ],
        );

      case 'drop_down':
        if (question['selection'] == 'multiple') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question['question'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              MultiSelectDialogField(
                items: options
                    .map<MultiSelectItem<String>>(
                        (opt) => MultiSelectItem<String>(
                              opt['option'].toString(),
                              opt['option'].toString(),
                            ))
                    .toList(),
                title: Text("Select Options"),
                selectedColor: Colors.blue,
                initialValue: (answers[index][question['question']] ?? [])
                    .map<String>((e) => e.toString())
                    .toList(),
                onConfirm: (values) {
                  setState(() {
                    if (question["title"] == 1 || question["title"] == "1") {
                      answers[index]['title'] = values.join(",");
                    }
                    answers[index][question['question']] = values;
                    print("po");
                    nextQuestion(question['next_question_id']);
                  });
                },
                chipDisplay: MultiSelectChipDisplay(),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question['question'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: answers[index][question['question']]?.toString() ?? null,
                items: options.map<DropdownMenuItem<String>>((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['option'].toString(),
                    child: Text(opt['option']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (question["title"] == 1 || question["title"] == "1") {
                      answers[index]['title'] = value;
                    }
                    answers[index][question['question']] = value;
                  });
                  final selected = options
                      .firstWhere((opt) => opt['option'].toString() == value);
                  nextQuestion(selected['next_question_id']);
                },
              ),
            ],
          );
        }

      case 'text':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question['question'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue:
                  answers[index][question['question']]?.toString() ?? '',
              onChanged: (val) {
                if (question["title"] == 1 || question["title"] == "1") {
                  answers[index]['title'] = val;
                }
                answers[index][question['question']] = val;
              },
              decoration: InputDecoration(hintText: "Enter your answer"),
            ),
            ElevatedButton(
              onPressed: () {
                int? nextId = question['next_question_id'];
                if (nextId != null) nextQuestion(nextId);
              },
              child: Text("Next"),
            ),
          ],
        );
    }
  }

  Widget _buildDropdown(
    String label,
    List<dynamic> items,
    String keyId,
    String keyName,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item[keyId].toString(),
                  child: Text(item[keyName] ?? ""),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (val) =>
            val == null || val.isEmpty ? 'Please select $label' : null,
      ),
    );
  }
}
