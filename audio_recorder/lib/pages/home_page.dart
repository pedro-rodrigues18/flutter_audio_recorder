import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isRecording = false;
  bool isPlaying = false;
  String? recordingPath;

  @override
  void initState() {
    super.initState();
    audioPlayer.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Microfone Demo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      floatingActionButton: _recordingButton(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (recordingPath != null) _audioPlayerWidget(),
          if (recordingPath == null) const Text('Nenhuma gravação encontrada'),
        ],
      ),
    );
  }

  Widget _audioPlayerWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (isPlaying) {
                  await audioPlayer.pause();
                } else {
                  await audioPlayer.setFilePath(recordingPath!);
                  await audioPlayer.play();
                }
              },
            ),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = audioPlayer.duration ?? Duration.zero;
                  return Column(
                    children: [
                      Slider(
                        value: position.inSeconds.toDouble(),
                        min: 0,
                        max: duration.inSeconds.toDouble(),
                        onChanged: (value) {
                          audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatDuration(position)),
                            Text(formatDuration(duration)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: () async {
        if (isRecording) {
          String? filePath = await audioRecorder.stop();

          if (filePath != null) {
            print('Audio salvo em: $filePath');
            setState(() {
              isRecording = false;
              recordingPath = filePath;
            });
          }
        } else {
          if (await audioRecorder.hasPermission()) {
            final Directory appDocumentsDir =
                await getApplicationDocumentsDirectory();
            final String filePath = p.join(appDocumentsDir.path, 'audio.wav');

            await audioRecorder.start(const RecordConfig(), path: filePath);

            setState(() {
              isRecording = true;
              recordingPath = null;
            });
          }
        }
      },
      child: Icon(
        isRecording ? Icons.stop : Icons.mic,
      ),
    );
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
