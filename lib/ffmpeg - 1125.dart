import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

// Data classes
class ImageData {
  int? index;
  final String path;
  final double startTime;
  final double duration;
  final int layer;
  final Offset pos;
  final Size size;
  final AnimationData inAnimation;
  final AnimationData outAnimation;

  ImageData({
    required this.path,
    required this.startTime,
    required this.duration,
    required this.layer,
    required this.pos,
    required this.size,
    required this.inAnimation,
    required this.outAnimation,
    this.index,
  });
}

class VideoData {
  int? index;
  final String path;
  final double startTime;
  final double duration;
  final int layer;
  Offset? pos;
  Size? size;
  final int audioFlag;
  //final double local_st;
  final AnimationData? inAnimation;
  final AnimationData? outAnimation;

  VideoData({
    required this.path,
    required this.startTime,
    required this.duration,
    required this.layer,
    required this.pos,
    required this.size,
    required this.audioFlag,
    //required this.local_st,
    this.inAnimation,
    this.outAnimation,
    this.index,
  });
}

class AudioData {
  final String path;
  final double startTime;
  final double duration;
  final double local_st;

  AudioData({
    required this.path,
    required this.startTime,
    required this.duration,
    required this.local_st,
  });
}

class AnimationData {
  final String type;
  final double duration;

  AnimationData({
    required this.type,
    required this.duration,
  });
}

// Build the FFmpeg command dynamically
Future<String> buildFFmpegCommand(
    double totalDuration,
    String backgroundColor,
    Size backgroundSize,
    int layerCount,
    //List<ImageData> images,
    List<VideoData> videos,
    //List<AudioData> audios,
    String outputPath,
    ) async {

  final directory = await getApplicationDocumentsDirectory();
  //outputPath = '${directory.path}/merged_video.mp4';
  String blank = '${directory.path}/blank.mp4';
  await runFFmpegCommand("-f lavfi -t 15 -i color=c=0x00FF00:s=1600x1200:r=30 -pix_fmt yuv420p ${blank}");

  int addIndex = 1;

  for(var video in videos) {
    video.index = addIndex;
    addIndex ++;

    if(video.inAnimation != null)
    {
      String animationOutput = '${directory.path}/animationVideo${video.index}.mp4';
      if(video.outAnimation != null)
        animationOutput = '${directory.path}/inAnimationVideo${video.index}.mp4';

      double duration = video.inAnimation!.duration; //InDuration
      double outDuration = video.outAnimation?.duration ?? 0.0; //OutDuration
      String animationCommand = "";
      double totalWidth = backgroundSize.width;
      double totalHeight = backgroundSize.height;

      switch(video.inAnimation!.type) {
        case "Fade In":
          animationCommand = "-i ${video.path} ${animationOutput}";
          break;
        case "Wipe Right In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipeleft:duration=${duration}:offset=0.0,scale=iw:ih\" ${animationOutput}";
          break;
        case "Wipe Left In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wiperight:duration=${duration}:offset=0.0,scale=iw:ih\" ${animationOutput}";
          break;
        case "Wipe Top In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipedown:duration=${duration}:offset=0.0,scale=iw:ih\" ${animationOutput}";
          break;
        case "Wipe Bottom In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipeup:duration=${duration}:offset=0.0,scale=iw:ih\" ${animationOutput}";
          break;
        case "Float Right In":
          double startX = 0;
          double dx = video.size!.width;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width * 2}:${video.size!.height}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='0':enable='between(t,0,${video.duration - outDuration})'\" ${animationOutput}";
          video.pos = Offset(video.pos!.dx - dx, video.pos!.dy);
          video.size = Size(video.size!.width * 2, video.size!.height);
          break;
        case "Float Left In":
          double startX = video.size!.width;
          double dx = 0;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width * 2}:${video.size!.height}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='0':enable='between(t,0,${video.duration - outDuration})'\" ${animationOutput}";
          video.size = Size(video.size!.width * 2, video.size!.height);
          break;
        case "Float Top In":
          double startY = 0;
          double dy = video.size!.height;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width}:${video.size!.height * 2}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='0':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})':enable='between(t,0,${video.duration- outDuration})'\" ${animationOutput}";
          video.pos = Offset(video.pos!.dx, video.pos!.dy - dy);
          video.size = Size(video.size!.width, video.size!.height * 2);
          break;
        case "Float Bottom In":
          double startY = video.size!.height;
          double dy = 0;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width}:${video.size!.height * 2}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='0':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})':enable='between(t,0,${video.duration- outDuration})'\" ${animationOutput}";
          video.size = Size(video.size!.width, video.size!.height * 2);
          break;
        case "Zoom In":
          //animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width}:${video.size!.height}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v1]scale='iw*if(lte(t,${duration}),0.7+(t/${duration})*0.3,1)':-1:eval=frame[v2];[v0][v2]overlay=x='(W-w)/2':y='(H-h)/2'\" ${animationOutput}";
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=2560:1440[v0];[1:v]scale=2560:1440[v1];[v1]scale='iw*if(lte(t,${duration}),0.7+(t/${duration})*0.3,1)':-1:eval=frame[v2];[v0][v2]overlay=x='(W-w)/2':y='(H-h)/2':enable='between(t,0,${video.duration - outDuration})'\" ${animationOutput}";
          break;
        case "Zoom Out":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=3328:1872[v0];[1:v]scale=2560:1440[v1];[v1]scale='iw*if(lte(t,${duration}),1.3-(t/${duration})*0.3,1)':-1:eval=frame[v2];[v0][v2]overlay=x='(W-w)/2':y='(H-h)/2':enable='between(t,0,${video.duration - outDuration})'\" ${animationOutput}";
          break;
        case "Slide Right In":
          double startX = -video.size!.width;
          double dx = video.pos!.dx;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='${video.pos!.dy}':enable='between(t,0,${video.duration - outDuration})'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Left In":
          double startX = totalWidth;
          double dx = video.pos!.dx;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='${video.pos!.dy}':enable='between(t,0,${video.duration - outDuration})'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Top In":
          double startY = -video.size!.height;
          double dy = video.pos!.dy;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='${video.pos!.dx}':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})':enable='between(t,0,${video.duration - outDuration})'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Bottom In":
          double startY = totalHeight;
          double dy = video.pos!.dy;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='${video.pos!.dx}':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})':enable='between(t,0,${video.duration - outDuration})'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        deafult:
          animationCommand = "";
          break;
      }

      print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      print(animationCommand);

      await runFFmpegCommand(animationCommand);
    }
  }

  String ffmpegCommand = '''-f lavfi -t $totalDuration -i color=c='$backgroundColor':s=${backgroundSize.width.toInt()}x${backgroundSize.height.toInt()}''';

  for (var video in videos) {
    if(video.inAnimation == null)
      ffmpegCommand += " -i ${video.path}";
    else {
      String animationPath = '${directory.path}/animationVideo${video.index}.mp4';
      ffmpegCommand += " -i ${animationPath}";
    }
  }

  ffmpegCommand += " -filter_complex \"";

  for(var i = 1; i <= layerCount; i++) {
    for (var video in videos) {
      if(video.layer == i) {
        var previous = "";
        var id = video.index;
        if(video.index == 1) {
          previous = "0:v";
        } else {
          previous = "result${video.index! - 1}";
        }
        var fadeCommand = "";//;
        if(!(video.inAnimation!.type.contains("Wipe") || video.inAnimation!.type.contains("Slide"))) {
          fadeCommand = ",fade=t=in:st=${video.startTime}:d=${video.inAnimation!.duration}:alpha=1";
        }

        ffmpegCommand += " [${id}:v]setpts=PTS+${video.startTime}/TB[delayed${id}];[delayed${id}]colorkey=0x00FF00:0.1:0.0[GR${id}];[GR${id}]scale=${video.size!.width}:${video.size!.height}${fadeCommand}[scaled${id}];[${previous}][scaled${id}]overlay=${video.pos!.dx}:${video.pos!.dy}:enable='between(t,${video.startTime},${video.startTime + video.duration})'[result${id}];";
      }
    }
  }

  var audioCommand = "";
  for (var video in videos) {
    if(video.audioFlag == 1) {
      var startTime  = video.startTime * 1000;
      audioCommand +=" [${video.index}:a]aselect='between(t,${video.startTime},${video.startTime + video.duration})',asetpts=PTS-STARTPTS[a${video.index}];[a${video.index}]adelay=${startTime}|${startTime}[audio${video.index}];";
    }
  }

  int audioCount = 0;
  for (var video in videos) {
    if(video.audioFlag == 1) {
      audioCommand +="[audio${video.index}]";
      audioCount ++;
    }
  }
  audioCommand += "amix=inputs=${audioCount}:duration=longest[aout]";

  ffmpegCommand += audioCommand + "\"";

  // deleteFile(blank);
  // for (var video in videos) {
  //   if(!(video.inAnimation == null || video.inAnimation!.type.contains("Fade")))
  //     deleteFile('${directory.path}/animationVideo${video.index}.mp4');
  // }
  // deleteFile(outputPath);

  return ffmpegCommand + " -map \"[result${addIndex-1}]\"  -map \"[aout]\" -c:v mpeg4 -c:a aac -pix_fmt yuv420p ${outputPath}";
}

// Execute the FFmpeg command
Future<void> renderVideo(String command) async {
  final session = await FFmpegKit.execute(command!);
  final returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    print("successful!");
  } else {
    final failStackTrace = await session.getFailStackTrace();
    print("Merge failed. Error: $failStackTrace");

    final logs = await session.getLogs();
    logs.forEach((log) {
      print(log.getMessage());
    });
  }
}

Future<void> runFFmpegCommand(String ffmpegCommand) async {
  final session = await FFmpegKit.execute(ffmpegCommand!);
  final returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    print("Animation Video Creation successful!");
  } else {
    final failStackTrace = await session.getFailStackTrace();
    print("Merge failed. Error: $failStackTrace");

    final logs = await session.getLogs();
    logs.forEach((log) {
      print(log.getMessage());
    });
  }
}

void deleteFile(String filePath) async {
  try {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
      print('File deleted successfully');
    } else {
      print('File does not exist');
    }
  } catch (e) {
    print('Error deleting file: $e');
  }
}