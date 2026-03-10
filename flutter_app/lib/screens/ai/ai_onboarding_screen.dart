import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

class AIOnboardingScreen extends StatefulWidget {
  const AIOnboardingScreen({super.key});

  @override
  State<AIOnboardingScreen> createState() => _AIOnboardingScreenState();
}

class _AIOnboardingScreenState extends State<AIOnboardingScreen> {

  int step = 0;

  String? occupationType;
  String occupationDetail = "";
  String? maritalStatus;
  String? talkFrequency;
  String? personalStatement;

  List<String> emotionalNeeds = [];

  final TextEditingController occupationController = TextEditingController();

  final List<String> emotionalOptions = [
    "Someone who listens without judging",
    "Help understanding my emotions",
    "Advice when I'm confused",
    "Motivation during difficult times",
    "A safe space to express myself",
    "Someone who understands women's experiences"
  ];

  Future saveProfile() async {

    final token = context.read<AuthProvider>().token;

    final url = Uri.parse("${ApiConfig.baseUrl}ai-profile/save");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "occupationType": occupationType,
        "occupationDetail": occupationDetail,
        "maritalStatus": maritalStatus,
        "talkFrequency": talkFrequency,
        "emotionalNeeds": emotionalNeeds,
        "personalStatement": personalStatement
      }),
    );

    print(response.body);

    if (mounted) {
      Navigator.pop(context);
    }

  }

  void nextStep() {
    setState(() {
      step++;
    });
  }

  Widget introScreen() {

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        const Text(
          "Your AI Companion will learn about you to support you better.",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        const Text(
          "Your answers help SARAN understand your preferences, emotions, and goals.",
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        ElevatedButton(
          onPressed: nextStep,
          child: const Text("Let's Begin"),
        )

      ],
    );
  }

  Widget occupationQuestion() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "What are you currently doing?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        RadioListTile(
          value: "student",
          groupValue: occupationType,
          title: const Text("Student"),
          onChanged: (v){
            setState(() => occupationType = v.toString());
          },
        ),

        RadioListTile(
          value: "homemaker",
          groupValue: occupationType,
          title: const Text("Home maker"),
          onChanged: (v){
            setState(() => occupationType = v.toString());
          },
        ),

        RadioListTile(
          value: "working",
          groupValue: occupationType,
          title: const Text("Working"),
          onChanged: (v){
            setState(() => occupationType = v.toString());
          },
        ),

        const SizedBox(height: 20),

        if (occupationType != null)
          TextField(
            controller: occupationController,
            decoration: const InputDecoration(
              labelText: "Tell us more (study/work details)"
            ),
          ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: (){
            occupationDetail = occupationController.text;
            nextStep();
          },
          child: const Text("Next"),
        )

      ],
    );
  }

  Widget maritalQuestion() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Marital Status",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        RadioListTile(
          value: "single",
          groupValue: maritalStatus,
          title: const Text("Single"),
          onChanged: (v){
            setState(() => maritalStatus = v.toString());
          },
        ),

        RadioListTile(
          value: "married",
          groupValue: maritalStatus,
          title: const Text("Married"),
          onChanged: (v){
            setState(() => maritalStatus = v.toString());
          },
        ),

        RadioListTile(
          value: "prefer_not",
          groupValue: maritalStatus,
          title: const Text("Prefer not to say"),
          onChanged: (v){
            setState(() => maritalStatus = v.toString());
          },
        ),

        ElevatedButton(
          onPressed: nextStep,
          child: const Text("Next"),
        )

      ],
    );
  }

  Widget frequencyQuestion() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "How often would you like to talk to your AI companion?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        ...[
          "Daily",
          "A few times a week",
          "Only when I need support",
          "Just exploring for now"
        ].map((e){

          return RadioListTile(
            value: e,
            groupValue: talkFrequency,
            title: Text(e),
            onChanged: (v){
              setState(() => talkFrequency = v.toString());
            },
          );

        }),

        ElevatedButton(
          onPressed: nextStep,
          child: const Text("Next"),
        )

      ],
    );
  }

  Widget emotionalNeedsQuestion() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "What kind of support do you expect from your AI companion?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        ...emotionalOptions.map((option){

          return CheckboxListTile(
            value: emotionalNeeds.contains(option),
            title: Text(option),
            onChanged: (v){

              setState(() {

                if (v == true) {
                  emotionalNeeds.add(option);
                } else {
                  emotionalNeeds.remove(option);
                }

              });

            },
          );

        }),

        ElevatedButton(
          onPressed: nextStep,
          child: const Text("Next"),
        )

      ],
    );
  }

  Widget statementQuestion() {

    final options = [

      "I sometimes wish I had more supportive conversations in my life",
      "I want someone I can talk to freely without fear of judgment",
      "I want to grow into a stronger version of myself",
      "I want to feel more confident and emotionally balanced"

    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Which statement feels closest to you?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        ...options.map((e){

          return RadioListTile(
            value: e,
            groupValue: personalStatement,
            title: Text(e),
            onChanged: (v){
              setState(() => personalStatement = v.toString());
            },
          );

        }),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: saveProfile,
          child: const Text("Finish"),
        )

      ],
    );
  }

  Widget buildStep() {

    switch(step) {

      case 0:
        return introScreen();

      case 1:
        return occupationQuestion();

      case 2:

        if (occupationType == "student" || occupationType == "homemaker") {
          step++;
          return frequencyQuestion();
        }

        return maritalQuestion();

      case 3:
        return frequencyQuestion();

      case 4:
        return emotionalNeedsQuestion();

      case 5:
        return statementQuestion();

      default:
        return const SizedBox();
    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("SARAN AI Setup"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: buildStep(),
      ),

    );

  }
}