import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
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
  VideoPlayerController? _videoController;
  String? ffmpegCommand;
  //String? outputPath = "${Directory.systemTemp.path}/merged_video.mp4";
  String? outputPath;

  Future<void> setOutputPath() async {
    final directory = await getApplicationDocumentsDirectory();
    outputPath = '${directory.path}/merged_video.mp4';
    print("outputPath: ${outputPath}");
  }
  // Function to pick two files
  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.length == 2) {
      file1Path = result.files[0].path;
      file2Path = result.files[1].path;
      setState(() {});
    } else {
      print("Please select exactly two files.");
    }
  }

  // Function to merge files using FFmpeg
  Future<String> mergeFiles(String? file1Path, String? file2Path) async {
    if (file1Path == null || file2Path == null) {
      print("Please select two files first.");
      return 'Failed';
    }

    String concatFilePath = await getConcatFilePath();

    return '-f concat -safe 0 -i $concatFilePath -c copy $outputPath';
  }

  // Function to create a temporary concat file for FFmpeg
  Future<String> getConcatFilePath() async {
    final concatFile = File("${Directory.systemTemp.path}/concat_list.txt");
    await concatFile.writeAsString("file '$file1Path'\nfile '$file2Path'\n");
    return concatFile.path;
  }

  // Function to create a blink background
  Future<String> createColoredBackground(int width, int height, int duration, int r, int g, int b) async {
    //String color = 'rgb:$r:$g:$b';
    String color = '#ff0000';
    return "-f lavfi -t $duration -i color=c=$color:s=${width}x${height} -c:v mpeg4  -pix_fmt yuv420p $outputPath";
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
                ffmpegCommand = await mergeFiles(file1Path, file2Path);
                //ffmpegCommand = await createColoredBackground(1920, 1080, 10, 255, 0, 0);
                print("*******************************************");
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
