import 'package:flutter/material.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/hointervention.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'ReeviewAnswersScreen.dart';
import 'endVisitScreen.dart';

class ProductCategoryInput extends StatefulWidget {
  final payload;
  final visit;
  final visitId;
  final visitStatus;
  final data;

  final type;
  final date;
  final meetingHappen;
  
  const ProductCategoryInput({
    this.visitStatus,
    this.data,this.type,this.date,this.meetingHappen,required this.visitId,required this.payload,required this.visit});

  @override
  State<ProductCategoryInput> createState() => _ProductCategoryInputState();
}

class _ProductCategoryInputState extends State<ProductCategoryInput> {
  List<Map<dynamic, dynamic>> answers = [{}];
  List<dynamic> categories = [];
  List<String?> selectedCategories = [];
  List<List<dynamic>> questionList = [[]];
  List<dynamic> questions = [];

  String? interested=null;
  String? selectedReason;
  String? daysNeeded;
  int selectedindex = 0;
  List<dynamic> reasons = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchReason();
  }

  fetchReason() async {
    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getReasonList',
        body: {},
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          reasons = data;
        });
      }
    } catch (error) {
      print("Error fetching reasons: $error");
    }
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

  getCategoryName(id) {
    var b =
        categories.where((element) => element['id'].toString() == id).toList();
    return b.isEmpty ? "" : b[0]['name'];
  }

  void nextQuestion(int nextQuestionId,que) {

    for(int i=0;i<que['options'].length;i++){

      questionList[selectedindex].removeWhere((element) => element['question_id']==que['options'][i]['next_question_id']);
    }
    final nextQ = questions.firstWhere(
      (q) => q['question_id'] == nextQuestionId,
      orElse: () => null,
    );
    if (nextQ != null &&
        !questionList[selectedindex]
            .any((q) => q['question_id'] == nextQ['question_id'])) {
      answers[selectedindex].removeWhere((key, value) =>key==nextQ['question']?.toString());
      setState(() {
        questionList[selectedindex].add(nextQ);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EndVisitScreen(

                  visit: widget.visit,
                  meetingHappen: widget.meetingHappen,
                  visitStatus:widget.visitStatus,
                  data:widget.data,
                  visitId: widget.visitId,
                  type: widget.type,
                  date: widget.date,
                ),
              ),
            );

          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                  child: ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text("In This Visit, did party show Interest in Products? ",style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                _buildDropdown(
                  "Interested in Products",
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
                if (interested == 'Yes')
                  ...List.generate(questionList.length, (index) {
                    return index == selectedindex
                        ? Card(
                          child: Column(
                              children: [
                                _buildDropdown(
                                  "Select Product Group",
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
                                ...questionList[index].map((q) => Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: _buildQuestionWidget(q, index),
                                )),
                                if (questionList[index].isNotEmpty &&
                                    questionList[index].last['final'] == 1)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
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
                            ),
                        )
                        : Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          getCategoryName(selectedCategories[
                                                  index]) ??
                                              "",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 20),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedindex = index;
                                              });
                                            },
                                            icon: Icon(Icons
                                                .remove_red_eye_outlined),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                questionList.removeAt(index);
                                                answers.removeAt(index);
                                                selectedCategories
                                                    .removeAt(index);
                                                if (selectedindex >= index &&
                                                    selectedindex > 0) {
                                                  selectedindex--;
                                                }
                                              });
                                            },
                                            icon: Icon(Icons.delete_outline,
                                                color: Colors.red),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  Text(
                                    answers[index]['title'] ?? '',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          );
                  }),
                interested != null && interested!.toLowerCase() == 'yes'
                    ? Container()
                    : interested!=null? Column(
                      children: [
                        _buildDropdown(
                            "Reason", reasons, "name", "name", selectedReason,
                            (value) {
                            setState(() {
                              selectedReason = value;
                            });
                          }),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text("How many more visits do you think are needed to close the deal ?",style: TextStyle(fontWeight: FontWeight.bold),),
                          ),
                           _buildDropdown(
                            "", [{"name":"0"},{"name":"1"},{"name":"2"},{"name":"3"}], "name", "name", daysNeeded,
                            (value) {
                            setState(() {
                              daysNeeded = value;
                            });
                          }),
                      ],
                    ):Container()
              ])),
              ElevatedButton.icon(
                onPressed: () {
                  if (interested!.toLowerCase() == 'yes') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewAnswersScreen(
                            answers: interested!.toLowerCase()=='yes'? answers:[],
                            payload: widget.payload,
                            date: widget.date,
                            category: interested!.toLowerCase()=='yes'? categories:[],
                            visit: widget.visit,
                            interested: selectedReason,
                            visitId:widget.visitId,
                          type: widget.type,
                          visitStatus:widget.visitStatus,
                          data:widget.data,
                          meetingHappen: widget.meetingHappen,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HoInterventionScreen(
                          type: widget.type,
                            answers: [],
                            meetingHappen: "yes",
                            date: widget.date,
                            payload: widget.payload,
                            visit: widget.visit,
                            visitId: widget.visitId,
                            visitStatus:widget.visitStatus,
                            data:widget.data,
                            interested: selectedReason),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.remove_red_eye_outlined),
                label: Text("Review"),
              ),
            ],
          ),
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
                  nextQuestion(opt['next_question_id'],question);
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
              Text(
                question['question'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Border color
                  borderRadius:
                      BorderRadius.circular(8), // Optional: rounded corners
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4), // Optional: inner spacing
                child: MultiSelectDialogField(
                  items: options
                      .map<MultiSelectItem<String>>(
                        (opt) => MultiSelectItem<String>(
                          opt['option'].toString(),
                          opt['option'].toString(),
                        ),
                      )
                      .toList(),
                  title: Text("Select Options"),
                  selectedColor: Colors.blue,
                  decoration:
                      BoxDecoration(), // Needed to remove internal field's decoration
                  initialValue: (answers[index][question['question']] ?? [])
                      .map<String>((e) => e.toString())
                      .toList(),
                  onConfirm: (values) {
                    setState(() {
                      if (question["title"] == 1 || question["title"] == "1") {
                        answers[index]['title'] = values.join(",");
                      }
                      answers[index][question['question']] = values;
                      nextQuestion(question['next_question_id'],question);
                    });
                  },
                  chipDisplay: MultiSelectChipDisplay(),
                ),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(question['question'],
              //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: answers[index][question['question']]?.toString() ?? null,
                decoration: InputDecoration(
                  labelText: question['question'],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
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

                  nextQuestion(question['next_question_id'] ??
                      selected['next_question_id'],question);
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
            // Text(question['question'],
            //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue:
                  answers[index][question['question']]?.toString() ?? '',
              decoration: InputDecoration(
                  labelText: question['question'],
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1.0, color: Colors.black),
                  ),
                  hintText: "Enter Here",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 1.0, color: Colors.black),
                  )),
              onChanged: (val) {
                if (question["title"] == 1 || question["title"] == "1") {
                  answers[index]['title'] = val;
                }
                answers[index][question['question']] = val;
              },
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     int? nextId = question['next_question_id'];
            //     if (nextId != null) nextQuestion(nextId);
            //   },
            //   child: Text("Next"),
            // ),
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
