import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/connectivity_service.dart';
import 'package:agri_tech_app/modeles/formation_modele.dart';

class FormationDetailPage extends StatefulWidget {
  final Formation formation;

  FormationDetailPage({required this.formation});

  @override
  _FormationDetailPageState createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> {
  late YoutubePlayerController _controller;
  bool _isVideoValid = true;

  @override
  void initState() {
    super.initState();

    String? videoId = YoutubePlayer.convertUrlToId(widget.formation.videoUrl);
    if (videoId == null) {
      _isVideoValid = false;
      print("Erreur : Impossible d'extraire l'ID de la vidéo.");
    }
    print("URL YouTube: ${widget.formation.videoUrl}");
    print("ID extrait: $videoId");

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "",
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOffline)
                      Padding(
                        padding: EdgeInsets.only(bottom: basePadding),
                        child: Text(
                          'Hors ligne - Vidéo indisponible',
                          style: GoogleFonts.lato(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: baseFontSize * 0.9 * textScaleFactor,
                          ),
                        ),
                      ),
                    Text(
                      isOffline ? '${widget.formation.titre} (local)' : widget.formation.titre,
                      style: GoogleFonts.lato(
                        fontSize: baseFontSize * 1.2 * textScaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: basePadding),
                    Text(
                      isOffline ? '${widget.formation.description} (local)' : widget.formation.description,
                      style: GoogleFonts.lato(
                        fontSize: baseFontSize * 0.9 * textScaleFactor,
                      ),
                    ),
                    SizedBox(height: basePadding * 2),
                    _isVideoValid && !isOffline
                        ? AspectRatio(
                            aspectRatio: 16 / 9,
                            child: YoutubePlayer(
                              controller: _controller,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: Colors.blueAccent,
                              progressColors: ProgressBarColors(
                                playedColor: Colors.blue,
                                handleColor: Colors.blueAccent,
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(basePadding),
                            child: Text(
                              isOffline
                                  ? 'Vidéo indisponible hors ligne'
                                  : 'Erreur : URL de la vidéo invalide',
                              style: GoogleFonts.lato(
                                fontSize: baseFontSize * 0.9 * textScaleFactor,
                                color: Colors.red,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      appBar: AppBar(
        title: Text(
          widget.formation.titre,
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
}