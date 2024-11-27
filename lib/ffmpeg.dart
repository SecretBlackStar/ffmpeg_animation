import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;

// Data classes
class ImageData {
  final String path;
  final double startTime;
  final double duration;
  final int layer;
  final Offset pos;
  final Size size;
  final AnimationData? inAnimation;
  final AnimationData? outAnimation;

  ImageData({
    required this.path,
    required this.startTime,
    required this.duration,
    required this.layer,
    required this.pos,
    required this.size,
    this.inAnimation,
    this.outAnimation,
  });
}

class TextData {
  final String fontFamily;
  final String textContent;
  final int fontSize;
  final int paddingLeft;
  final int paddingTop;
  final int paddingRight;
  final Color? backgroundColor;
  final Color fontColor;
  final TextAlign textAlign;
  final double startTime;
  final double duration;
  final int layer;
  final Offset pos;
  final Size size;
  final AnimationData? inAnimation;
  final AnimationData? outAnimation;

  TextData({
    required this.fontFamily,
    required this.textContent,
    required this.fontSize,
    required this.paddingLeft,
    required this.paddingTop,
    required this.paddingRight,
    required this.backgroundColor,
    required this.fontColor,
    required this.textAlign,
    required this.startTime,
    required this.duration,
    required this.layer,
    required this.pos,
    required this.size,
    this.inAnimation,
    this.outAnimation,
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
  int? oringalFlag;
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
    this.oringalFlag
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
    Color backgroundColor,
    Size backgroundSize,
    int layerCount,
    String outputPath,
    {
    List<ImageData>? images,
    List<VideoData>? videos,
    List<AudioData>? audios,
    List<TextData>? texts,
    }) async {

  final directory = await getApplicationDocumentsDirectory();
  //outputPath = '${directory.path}/merged_video.mp4';
  String blank = '${directory.path}/blank.mp4';
  await runFFmpegCommand("-f lavfi -t ${totalDuration} -i color=c=0x00FF00:s=1600x1200:r=30 -pix_fmt yuv420p ${blank}", blank);

  int index = 1;
  if(texts != null) {
    for(var text in texts!) {
      String textVideoPath = '${directory.path}/textVideo${index}.mp4';
      String fontPath = await getFontPath(text.fontFamily);

      String bgColor = "";
      if(text.backgroundColor != null)
        bgColor = '0x${text.backgroundColor!.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      else
        bgColor = "0x00FF00";

      String fontColorHex = '0x${text.fontColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

      List<String> lines = text.textContent.split('\n');
      String textCommand = "-f lavfi -t ${text.duration} -i color=c=${bgColor}:s=${text.size.width.toInt()}x${text.size.height.toInt()}:r=30 -vf \"";
      for(int i = 0; i < lines.length; i++) {
        String align = '';

        if (text.textAlign == TextAlign.center) {
          align = 'x=(w-text_w)/2';
        } else if (text.textAlign == TextAlign.left) {
          align = 'x=${text.paddingLeft}';
        } else if(text.textAlign == TextAlign.right) {
          align = 'x=(w-text_w-${text.paddingRight})';
        }
        align += ':y=${text.paddingTop + text.fontSize * i}';

        if(i != 0)  textCommand += ",";
        textCommand += "drawtext=fontfile=${fontPath}:text='${lines[i]}':fontcolor=${fontColorHex}:fontsize=${text.fontSize}:${align}";
      }

      textCommand += "\" -pix_fmt yuv420p ${textVideoPath}";

      await runFFmpegCommand(textCommand, textVideoPath);

      videos!.add(VideoData(path: textVideoPath, startTime: text.startTime, duration: text.duration, layer: text.layer, pos: text.pos, size: text.size, audioFlag: 0, inAnimation: text.inAnimation, outAnimation: text.outAnimation));
      index ++;
    }
  }

  if(images != null ){
    index = 1;
    for(var image in images!) {
      String imageVideoPath = '${directory.path}/imageVideo${index}.mp4';
      await runFFmpegCommand("-loop 1 -i ${image.path} -t ${image.duration} ${imageVideoPath}", imageVideoPath);
      videos!.add(VideoData(path: imageVideoPath, startTime: image.startTime, duration: image.duration, layer: image.layer, pos: image.pos, size: image.size, audioFlag: 0, inAnimation: image.inAnimation, outAnimation: image.outAnimation));
      index++;
    }
  }

  int addIndex = 1;
  List<VideoData> clipedVideos = [];

  for(var video in videos!) {
    double inDuration = video.inAnimation?.duration ?? 0.0;
    double outDuration = video.outAnimation?.duration ?? 0.0;
    double duration = video.duration;

    if(inDuration != 0) {
      var inClipPath = '${directory.path}/inClip${addIndex}.mp4';
      await runFFmpegCommand("-i ${video.path} -ss 0 -to ${inDuration} ${inClipPath}", inClipPath);
      clipedVideos.add(VideoData(path: inClipPath, startTime: video.startTime, duration: inDuration, layer: video.layer, pos: video.pos, size: video.size, audioFlag: video.audioFlag, inAnimation: video.inAnimation, oringalFlag: 0, index: addIndex));
      addIndex ++;
    }

    var originalPath = '${directory.path}/original${addIndex}.mp4';
    await runFFmpegCommand("-i ${video.path} -ss ${inDuration} -to ${duration - outDuration} ${originalPath}", originalPath);
    clipedVideos.add(VideoData(path: originalPath, startTime: video.startTime + inDuration, duration: duration - inDuration - outDuration, layer: video.layer, pos: video.pos, size: video.size, audioFlag: video.audioFlag, oringalFlag: 1, index: addIndex));
    addIndex ++;


    if(outDuration != 0) {
      var outClipPath = '${directory.path}/outClip${addIndex}.mp4';
      await runFFmpegCommand("-i ${video.path} -ss ${duration - outDuration} -to ${duration} ${outClipPath}", outClipPath);
      clipedVideos.add(VideoData(path: outClipPath, startTime: video.startTime + duration - outDuration, duration: outDuration, layer: video.layer, pos: video.pos, size: video.size, audioFlag: video.audioFlag, outAnimation: video.outAnimation, oringalFlag: 0, index: addIndex));
      addIndex ++;
    }
  }

  for(var video in clipedVideos) {
    if(video.inAnimation != null)
    {
      String animationOutput = '-g 30 -c:v libx264 ${directory.path}/editedVideo${video.index}.mp4';
      double duration = video.inAnimation!.duration;
      String animationCommand = "";
      double totalWidth = backgroundSize.width;
      double totalHeight = backgroundSize.height;

      switch(video.inAnimation!.type) {
        case "Fade In":
          animationCommand = "-i ${video.path} ${animationOutput}";
          break;
        case "Wipe Right In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipeleft:duration=${duration}:offset=0.0\" -y ${animationOutput}";
          break;
        case "Wipe Left In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wiperight:duration=${duration}:offset=0.0\" ${animationOutput}";
          break;
        case "Wipe Top In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipedown:duration=${duration}:offset=0.0\" ${animationOutput}";
          break;
        case "Wipe Bottom In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipeup:duration=${duration}:offset=0.0\" ${animationOutput}";
          break;
        case "Float Right In":
          double startX = 0;
          double dx = video.size!.width;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width * 2}:${video.size!.height}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='0'\" ${animationOutput}";
          video.pos = Offset(video.pos!.dx - dx, video.pos!.dy);
          video.size = Size(video.size!.width * 2, video.size!.height);
          break;
        case "Float Left In":
          double startX = video.size!.width;
          double dx = 0;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width * 2}:${video.size!.height}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='0'\" ${animationOutput}";
          video.size = Size(video.size!.width * 2, video.size!.height);
          break;
        case "Float Bottom In":
          double startY = 0;
          double dy = video.size!.height;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width}:${video.size!.height * 2}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='0':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})'\" ${animationOutput}";
          video.pos = Offset(video.pos!.dx, video.pos!.dy - dy);
          video.size = Size(video.size!.width, video.size!.height * 2);
          break;
        case "Float Top In":
          double startY = video.size!.height;
          double dy = 0;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width}:${video.size!.height * 2}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='0':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})'\" ${animationOutput}";
          video.size = Size(video.size!.width, video.size!.height * 2);
          break;
        case "Zoom In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=2560:1440[v0];[1:v]scale=2560:1440[v1];[v1]scale='iw*if(lte(t,${duration}),0.7+(t/${duration})*0.3,1)':-1:eval=frame[v2];[v0][v2]overlay=x='(W-w)/2':y='(H-h)/2'\" ${animationOutput}";
          break;
        case "Drop In":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=3328:1872[v0];[1:v]scale=2560:1440[v1];[v1]scale='iw*if(lte(t,${duration}),1.3-(t/${duration})*0.3,1)':-1:eval=frame[v2];[v0][v2]overlay=x='(W-w)/2':y='(H-h)/2'\" ${animationOutput}";
          video.size = Size(video.size!.width * 1.3, video.size!.height * 1.3);
          video.pos = Offset(video.pos!.dx - video.size!.width / 1.3 * 0.15, video.pos!.dy - video.size!.height / 1.3 * 0.15);
          break;
        case "Slide Right In":
          double startX = -video.size!.width;
          double dx = video.pos!.dx;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='${video.pos!.dy}'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Left In":
          double startX = totalWidth;
          double dx = video.pos!.dx;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='${video.pos!.dy}'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Top In":
          double startY = totalHeight;
          double dy = video.pos!.dy;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='${video.pos!.dx}':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Bottom In":
          double startY = -video.size!.height;
          double dy = video.pos!.dy;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='${video.pos!.dx}':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        deafult:
          animationCommand = "";
          break;
      }

      await runFFmpegCommand(animationCommand, animationOutput);
    } else if(video.outAnimation != null) {
      String animationOutput = '-c:v libx264 ${directory.path}/editedVideo${video.index}.mp4';
      double duration = video.outAnimation!.duration;
      String animationCommand = "";
      double totalWidth = backgroundSize.width;
      double totalHeight = backgroundSize.height;

      switch(video.outAnimation!.type) {
        case "Fade Out":
          animationCommand = "-i ${video.path} ${animationOutput}";
          break;
        // case "Wipe Right In":
        //   animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipeleft:duration=${duration}:offset=0.0\" -y ${animationOutput}";
        //   break;
        // case "Wipe Left In":
        //   animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wiperight:duration=${duration}:offset=0.0\" ${animationOutput}";
        //   break;
        // case "Wipe Top In":
        //   animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipedown:duration=${duration}:offset=0.0\" ${animationOutput}";
        //   break;
        // case "Wipe Bottom In":
        //   animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]fps=30,scale=1280x720[v0];[1:v]fps=30,scale=1280x720[v1];[v0][v1]xfade=transition=wipeup:duration=${duration}:offset=0.0\" ${animationOutput}";
        //   break;
        case "Float Right Out":
          double startX = 0;
          double dx = video.size!.width;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width * 2}:${video.size!.height}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='0'\" ${animationOutput}";
          video.size = Size(video.size!.width * 2, video.size!.height);
          break;
        case "Float Left Out":
          double startX = video.size!.width;
          double dx = 0;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width * 2}:${video.size!.height}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='0'\" ${animationOutput}";
          video.pos = Offset(video.pos!.dx - startX, video.pos!.dy);
          video.size = Size(video.size!.width * 2, video.size!.height);
          break;
        case "Float Bottom Out":
          double startY = 0;
          double dy = video.size!.height;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width}:${video.size!.height * 2}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='0':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})'\" ${animationOutput}";
          video.size = Size(video.size!.width, video.size!.height * 2);
          break;
        case "Float Top Out":
          double startY = video.size!.height;
          double dy = 0;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${video.size!.width}:${video.size!.height * 2}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='0':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})'\" ${animationOutput}";
          video.pos = Offset(video.pos!.dx, video.pos!.dy - startY);
          video.size = Size(video.size!.width, video.size!.height * 2);
          break;
        case "Zoom Out":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=3328:1872[v0];[1:v]scale=2560:1440[v1];[v1]scale='iw*if(lte(t,${duration}),1+(t/${duration})*0.3,1)':-1:eval=frame[v2];[v0][v2]overlay=x='(W-w)/2':y='(H-h)/2'\" ${animationOutput}";
          video.size = Size(video.size!.width * 1.3, video.size!.height * 1.3);
          video.pos = Offset(video.pos!.dx - video.size!.width / 1.3 * 0.15, video.pos!.dy - video.size!.height / 1.3 * 0.15);
          break;
        case "Drop Out":
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=2560:1440[v0];[1:v]scale=2560:1440[v1];[v1]scale='iw*if(lte(t,${duration}),1-(t/${duration})*0.3,1)':-1:eval=frame[v2];[v0][v2]overlay=x='(W-w)/2':y='(H-h)/2'\" ${animationOutput}";
          break;
        case "Slide Right Out":
          double startX = video.pos!.dx;
          double dx = totalWidth;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='${video.pos!.dy}'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Left Out":
          double startX = video.pos!.dx;
          double dx = -video.size!.width;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='if(lte(t,${duration}), ${startX} + (${dx} - ${startX})*t/${duration}, ${dx})':y='${video.pos!.dy}'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Top Out":
          double startY = video.pos!.dy;
          double dy = -video.size!.height;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='${video.pos!.dx}':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        case "Slide Bottom Out":
          double startY = video.pos!.dy;
          double dy = totalHeight;
          animationCommand = "-i ${blank} -i ${video.path} -filter_complex \"[0:v]scale=${totalWidth}:${totalHeight}[v0];[1:v]scale=${video.size!.width}:${video.size!.height}[v1];[v0][v1]overlay=x='${video.pos!.dx}':y='if(lte(t,${duration}), ${startY} + (${dy} - ${startY})*t/${duration}, ${dy})'\" ${animationOutput}";
          video.pos = Offset(0.0, 0.0);
          video.size = Size(totalWidth, totalHeight);
          break;
        deafult:
          animationCommand = "";
          break;
      }

      await runFFmpegCommand(animationCommand, animationOutput);
    }
  }

  String bBGColor = '0x${backgroundColor!.value.toRadixString(16).padLeft(8, '0').substring(2)}';

  String ffmpegCommand = '''-f lavfi -t $totalDuration -i color=c='$bBGColor':s=${backgroundSize.width.toInt()}x${backgroundSize.height.toInt()}''';

  for (var video in clipedVideos) {
    if(video.inAnimation != null || video.outAnimation != null) {
      String path = '${directory.path}/editedVideo${video.index}.mp4';
      ffmpegCommand += " -i ${path}";
    }
    else {
      String path = '${directory.path}/original${video.index}.mp4';
      ffmpegCommand += " -i ${path}";
    }
  }

  ffmpegCommand += " -filter_complex \"";

  for(var i = 1; i <= layerCount; i++) {
    for (var video in clipedVideos) {

      if(video.layer == i) {
        var previous = "";
        var id = video.index;
        if(video.index == 1) {
          previous = "0:v";
        } else {
          previous = "result${video.index! - 1}";
        }
        var fadeCommand = "";
        if(video.inAnimation != null) {
          if(!(video.inAnimation!.type.contains("Wipe") || video.inAnimation!.type.contains("Slide"))) {
            fadeCommand = ",fade=t=in:st=${video.startTime}:d=${video.inAnimation!.duration}:alpha=1";
          }
        } else if(video.outAnimation != null) {
          if(!(video.outAnimation!.type.contains("Wipe") || video.outAnimation!.type.contains("Slide"))) {
            fadeCommand = ",fade=t=out:st=${video.startTime}:d=${video.outAnimation!.duration}:alpha=1";
          }
        }

        ffmpegCommand += " [${id}:v]setpts=PTS+${video.startTime}/TB[delayed${id}];[delayed${id}]colorkey=0x00FF00:0.2:0.1[GR${id}];[GR${id}]scale=${video.size!.width}:${video.size!.height}${fadeCommand}[scaled${id}];[${previous}][scaled${id}]overlay=${video.pos!.dx}:${video.pos!.dy}:enable='between(t,${video.startTime},${video.startTime + video.duration})'[result${id}];";

      }
    }
  }

  var audioCommand = "";
  for (var video in clipedVideos) {
    if(video.audioFlag == 1) {
      var startTime  = video.startTime * 1000;
      audioCommand +=" [${video.index}:a]aselect='between(t,0,${video.duration})',asetpts=PTS-STARTPTS[a${video.index}];[a${video.index}]adelay=${startTime}|${startTime}[audio${video.index}];";
      //audioCommand +=" [${video.index}:a]aselect='between(t,${video.startTime},${video.startTime + video.duration})',asetpts=PTS-STARTPTS[a${video.index}];[a${video.index}]adelay=${startTime}|${startTime}[audio${video.index}];";
    }
  }

  int audioCount = 0;
  for (var video in clipedVideos) {
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

Future<void> runFFmpegCommand(String ffmpegCommand, String filePath) async {
  print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  print(ffmpegCommand);

  deleteFile(filePath);

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

Future<String> getFontPath(String fontFamily) async {
  String fontFileName = "";

  switch(fontFamily) {
    case "SourGummy":
      fontFileName="SourGummy.ttf";
      break;
    case "Momcake":
      fontFileName="MomcakeThin-9Y6aZ.otf";
      break;
    case "Lemon Milk":
      fontFileName="LemonMilkMedium-mLZYV.otf";
      break;
    case "Forzan":
      fontFileName="ForzanLight-ALWAA.ttf";
      break;
    case "Salmapro":
      fontFileName="SalmaproMedium-yw9ad.otf";
      break;
    case "Good Unicorn":
      fontFileName="GoodUnicornRegular-Rxev.ttf";
      break;
    case "Blanks Script":
      fontFileName="BlanksscriptpersonaluseBdit-jEM6O.otf";
      break;
    case "Vergilia":
      fontFileName="Vergilia-mL6aa.ttf";
      break;
    case "Rantys":
      fontFileName="RantysFreeRegular-p7A0y.otf";
      break;
    case "Glutern Serif":
      fontFileName="GluternSerif-ZVv2z.otf";
      break;
    case "Vintage Postcard":
      fontFileName="VintagePostcard-z8XY3.ttf";
      break;
    case "Beautiful Blossoms":
      fontFileName="BeautifulBlossoms-2OGlX.ttf";
      break;
    case "Vacation Postcard":
      fontFileName="VacationPostcardNf-gDnP.ttf";
      break;
  }

  final byteData = await rootBundle.load('assets/fonts/${fontFileName}');

  final tempDir = await getTemporaryDirectory();

  final fontFile = File('${tempDir.path}/${fontFileName}');
  await fontFile.writeAsBytes(byteData.buffer.asUint8List());

  return fontFile.path;
}