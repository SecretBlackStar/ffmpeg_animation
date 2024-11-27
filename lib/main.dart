import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'ffmpeg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? file1Path;
  String? file2Path;
  String? file3Path;
  String? image1Path;
  String? image2Path;
  VideoPlayerController? _videoController;
  String? ffmpegCommand;
  //String? outputPath = "${Directory.systemTemp.path}/merged_video.mp4";
  String? outputPath;
  String? removeGreen;

  Future<void> setOutputPath() async {
    final directory = await getApplicationDocumentsDirectory();
    outputPath = '${directory.path}/merged_video.mp4';
    removeGreen = '${directory.path}/result.mp4';
  }
  // Function to pick two files
  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.length == 5) {
      //file1Path = "/data/user/0/com.example.ffmpeg_test/cache/file_picker/re1.mp4";//result.files[0].path;
      //file2Path = "/data/user/0/com.example.ffmpeg_test/cache/file_picker/re2.mp4";//result.files[1].path;
      //file3Path = "/data/user/0/com.example.ffmpeg_test/cache/file_picker/re4.mp4";//result.files[2].path;

      image1Path = result.files[0].path;
      image2Path = result.files[1].path;
      file1Path = result.files[2].path;
      file2Path = result.files[3].path;
      file3Path = result.files[4].path;
      setState(() {});
    } else {
      print("Please select exactly two files.");
    }
  }

  Future<void> runFFmpegCommand() async {
    final session = await FFmpegKit.execute(ffmpegCommand!);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      print("Merge successful! Output file at: $outputPath");
      _initializeVideoPlayer();
    } else {
      final failStackTrace = await session.getFailStackTrace();
      print("Merge failed. Error: $failStackTrace");

      final logs = await session.getLogs();
      logs.forEach((log) {
        print(log.getMessage());
      });
    }
  }

  // Initialize video player with the output video file
  Future<void> _initializeVideoPlayer() async {
    if (outputPath == null) return;

    _videoController = VideoPlayerController.file(File(outputPath!))
      ..initialize().then((_) {
        setState(() {}); // Refresh to display the video player
        _videoController!.play(); // Auto-play the video after merging
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (file1Path != null && file2Path != null)
              Text('File 1: $file1Path\nFile 2: $file2Path'),
            SizedBox(height: 20),

            ElevatedButton(
              child: Text('Pick Two Video Files'),
              onPressed: pickFiles,
            ),
            SizedBox(height: 20),

            ElevatedButton(
              child: Text('Merge Videos'),
              onPressed: () async {
                setOutputPath();
                //Videos
                List<VideoData> videos = [];
                AnimationData animation1 = AnimationData(type: ("Slide Right In"), duration: 1);
                AnimationData animation2 = AnimationData(type: ("Zoom In"), duration: 0.5);
                AnimationData animation3 = AnimationData(type: ("Drop In"), duration: 1);

                AnimationData outAnimation1 = AnimationData(type: ("Float Right Out"), duration: 1);
                AnimationData outAnimation2 = AnimationData(type: ("Zoom Out"), duration: 0.5);
                AnimationData outAnimation3 = AnimationData(type: ("Drop Out"), duration: 1);

                videos.add(VideoData(path: file1Path!, startTime: 5.0, duration: 10.0, layer: 2, audioFlag: 1, pos:Offset(50.0, 100.0), size: Size(150.0, 100.0), inAnimation: animation1, outAnimation: outAnimation1));
                videos.add(VideoData(path: file2Path!, startTime: 0.0, duration: 25.0, layer: 1, audioFlag: 0, pos:Offset(0.0, 0.0), size: Size(600.0, 400.0), inAnimation: animation2, outAnimation: outAnimation2));
                videos.add(VideoData(path: file3Path!, startTime: 20.0, duration: 10.0, layer: 3, audioFlag: 1, pos:Offset(300.0, 50.0), size: Size(150.0, 100.0), inAnimation: animation3, outAnimation: outAnimation3));

                //Images
                //List<ImageData> images = [];
                //images.add(ImageData(path: image1Path!, startTime: 0, duration: 15.0, layer: 3, pos: Offset(100, 100), size: Size(100,120), inAnimation: animation1, outAnimation: outAnimation1));
                //images.add(ImageData(path: image2Path!, startTime: 15.0, duration: 15.0, layer: 3, pos: Offset(20, 20), size: Size(150,150), inAnimation: animation2, outAnimation: outAnimation2));

                //Texts
                List<TextData> texts = [];
                AnimationData textanimation1 = AnimationData(type: ("Slide Right In"), duration: 1);
                AnimationData outTextanimation1 = AnimationData(type: ("Slide Left Out"), duration: 1);
                texts.add(TextData(fontFamily: "Lemon Milk", textContent: "Hello\nHello", fontSize: 50, paddingLeft: 0, paddingTop: 0, paddingRight: 0, backgroundColor: Colors.black, fontColor: Colors.cyanAccent, textAlign: TextAlign.center, startTime: 0, duration: 10, layer: 2, pos: Offset(100, 0), size: Size(178.3, 100), inAnimation: textanimation1, outAnimation: outTextanimation1));

                //videos.add(VideoData(path: file2Path, startTime: 10.0, duration: 10.0));
                print("*******************************************");
                ffmpegCommand = await buildFFmpegCommand(30.0, Colors.black, Size(600, 600), 3, outputPath!, videos: videos, texts: texts);

                print(ffmpegCommand);
                await runFFmpegCommand();
              },
            ),
            SizedBox(height: 20),

            // Display the video player if the video is ready
            if (_videoController != null && _videoController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),

            if (outputPath != null)
              Text('Merged file: $outputPath'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Do nothing for now',
        child: const Icon(Icons.add),
      ),
    );
  }
}
