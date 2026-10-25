import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/connectivity_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String titre;

  const VideoPlayerScreen({
    required this.videoUrl,
    required this.titre,
    Key? key,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isVideoValid = true;
  String? _videoId;

  @override
  void initState() {
    super.initState();

    _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    debugPrint("ID vidéo extrait: $_videoId");

    if (_videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: false,
          hideControls: false,
          controlsVisibleAtStart: true,
        ),
      );
    } else {
      _isVideoValid = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;

    return Scaffold(
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return Column(
              children: [
                if (isOffline)
                  Padding(
                    padding: EdgeInsets.all(basePadding),
                    child: Text(
                      'Hors ligne - Vidéo indisponible',
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.9 * textScaleFactor,
                      ),
                    ),
                  ),
                _isVideoValid && !isOffline
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: YoutubePlayer(
                          controller: _controller,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: Colors.green,
                          progressColors: const ProgressBarColors(
                            playedColor: Colors.green,
                            handleColor: Colors.greenAccent,
                          ),
                          onReady: () => debugPrint('Lecteur prêt'),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.all(basePadding),
                        child: Text(
                          isOffline
                              ? 'Vidéo indisponible hors ligne'
                              : 'Erreur : L\'URL de la vidéo est invalide.',
                          style: GoogleFonts.lato(
                            fontSize: baseFontSize * 0.9 * textScaleFactor,
                            color: Colors.red,
                          ),
                        ),
                      ),
                _buildVideoInfo(isOffline, baseFontSize, textScaleFactor, basePadding),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        title: Text(
          widget.titre,
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Widget _buildVideoInfo(bool isOffline, double baseFontSize, double textScaleFactor, double basePadding) {
    return Padding(
      padding: EdgeInsets.all(basePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOffline ? "${widget.titre} (local)" : widget.titre,
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 1.1 * textScaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: basePadding),
          Text(
            "Description détaillée de la formation...",
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 0.9 * textScaleFactor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isVideoValid) {
      _controller.dispose();
    }
    super.dispose();
  }
}