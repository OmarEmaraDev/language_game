import "dart:math";
import "dart:convert";
import "package:flutter/material.dart";
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(LanguageGame());
}

class LanguageGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Language Game",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        buttonColor: Theme.of(context).accentColor,
      ),
      routes: {
        "/": (context) => LanguageGameHome(),
        "/animals": (context) => AnimalsGame(),
        "/credits": (context) => Credits(),
      },
    );
  }
}

class Credits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(fontSize: 32);
    return Scaffold(
      appBar: AppBar(
        title: Text("Credits"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text("Animal assets: kenney.nl", style: style),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
      ),
    );
  }
}

class LanguageGameHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Language Game"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            getRaisedButton(
                context: context, text: "Animals game", route: "/animals"),
            getRaisedButton(
                context: context, text: "Credits", route: "/credits"),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
      ),
    );
  }

  RaisedButton getRaisedButton(
      {BuildContext context, String text, String route}) {
    return RaisedButton(
      padding: EdgeInsets.all(16.0),
      child: Text(text,
          style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white)),
      onPressed: () {
        Navigator.pushNamed(
          context,
          route,
        );
      },
    );
  }
}

class AnimalsGame extends StatefulWidget {
  AnimalsGame({Key key}) : super(key: key);
  createState() => AnimalsGameState();
}

class AnimalsGameState extends State<AnimalsGame> {
  String letter;
  String correctChoice;
  String wrongChoice;

  @override
  void initState() {
    super.initState();
    setRandomState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Animals Game"),
      ),
      body: (letter == null)
          ? null
          : Center(
              child: Column(
                children: <Widget>[
                  AnimalGameTitle(letter.toUpperCase()),
                  AnimalGameDragTarget(correctChoice),
                  AnimalGameChoices(correctChoice, wrongChoice),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: setRandomState,
        tooltip: 'New',
        child: Icon(Icons.navigate_next),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void setRandomState() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final imagePaths = manifestMap.keys
        .where((String key) => key.startsWith("images/animals/"))
        .toList();
    final Random rng = Random();
    setState(() {
      correctChoice = imagePaths[rng.nextInt(imagePaths.length)];
      letter = correctChoice.split("/").last.substring(0, 1);
      do {
        wrongChoice = imagePaths[rng.nextInt(imagePaths.length)];
      } while (wrongChoice.split("/").last.substring(0, 1) == letter);
    });
  }
}

class AnimalGameTitle extends StatelessWidget {
  final String letter;

  AnimalGameTitle(this.letter);

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = Theme.of(context).textTheme.headline4;
    return Padding(
      padding: EdgeInsets.all(64.0),
      child: Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(
                text: "Drag the animal that starts with the letter ",
                style: titleStyle.copyWith(color: Colors.black)),
            TextSpan(
                text: letter,
                style:
                    titleStyle.copyWith(color: Theme.of(context).accentColor)),
          ],
        ),
      ),
    );
  }
}

class AnimalGameDragTarget extends StatefulWidget {
  final String correctChoice;
  AnimalGameDragTarget(this.correctChoice, {Key key}) : super(key: key);
  createState() => AnimalGameDragTargetState();
}

enum ChoiceValidity { noChoice, rightChoice, wrongChoice }

class AnimalGameDragTargetState extends State<AnimalGameDragTarget> {
  ChoiceValidity choiceValidity = ChoiceValidity.noChoice;

  ConfettiController confettiController;

  @override
  void initState() {
    super.initState();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimalGameDragTarget oldWidget) {
    choiceValidity = ChoiceValidity.noChoice;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (String data) => (data == widget.correctChoice),
      onAccept: (String data) {
        confettiController.play();
        setState(() {
          choiceValidity = ChoiceValidity.rightChoice;
        });
      },
      builder: (BuildContext context, List<String> candidateData,
          List<dynamic> rejectedData) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).accentColor,
              width: 4,
            ),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(
              Radius.circular(20.0),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              getBuilderChild(choiceValidity),
              Center(
                  child: ConfettiWidget(
                confettiController: confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 1,
                numberOfParticles: 1,
              )),
            ],
          ),
        );
      },
    );
  }

  Widget getBuilderChild(ChoiceValidity choiceValidity) {
    if (choiceValidity == ChoiceValidity.noChoice) {
      return Container();
    } else {
      return Image.asset(widget.correctChoice);
    }
  }
}

class AnimalGameChoices extends StatelessWidget {
  final String firstChoice;
  final String secondChoice;

  AnimalGameChoices(this.firstChoice, this.secondChoice);

  @override
  Widget build(BuildContext context) {
    List<Widget> draggables = <Widget>[
      Draggable<String>(
          data: firstChoice,
          child: Image.asset(firstChoice),
          feedback: Image.asset(firstChoice),
          childWhenDragging: Image.asset(
            firstChoice,
            color: Colors.white.withOpacity(0.2),
            colorBlendMode: BlendMode.modulate,
          )),
      Draggable<String>(
          data: secondChoice,
          child: Image.asset(secondChoice),
          feedback: Image.asset(secondChoice),
          childWhenDragging: Image.asset(
            secondChoice,
            color: Colors.white.withOpacity(0.2),
            colorBlendMode: BlendMode.modulate,
          )),
    ];
    draggables.shuffle();
    return Padding(
      padding: EdgeInsets.all(64.0),
      child: Row(
        children: draggables,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }
}
