import 'package:agri_tech_app/ecrans/accueil/ecran_accueil.dart';
import 'package:agri_tech_app/ecrans/accueil/accueil_cooperative.dart';
import 'package:flutter/material.dart';
import 'ecrans/accueil/bienvenue.dart';
import 'ecrans/authentification/ecran_connexion.dart';
import 'ecrans/authentification/ecran_inscription.dart';
import 'ecrans/authentification/reinitialisation_mdp.dart';
import 'ecrans/authentification/PageProfil.dart';
import 'package:agri_tech_app/ecrans/authentification/ModifierPage.dart';
import 'package:agri_tech_app/ecrans/barre_latteral/Utilisateur_profil.dart';
import 'package:agri_tech_app/ecrans/Rapport/rapport_culture.dart';
import 'package:agri_tech_app/ecrans/formations/ConseilsPage.dart';
import 'package:agri_tech_app/ecrans/formations/ajout_conseil.dart';
import 'package:agri_tech_app/ecrans/accueil/ecran_accueil.dart';
import 'package:agri_tech_app/ecrans/cooperative/ajout_membre.dart';
import 'package:agri_tech_app/ecrans/cooperative/ajout_recolte_page.dart';
import 'package:agri_tech_app/ecrans/cooperative/membres_page.dart';
import 'package:agri_tech_app/ecrans/cooperative/DetailRecoltePage.dart';
import 'package:agri_tech_app/ecrans/cooperative/editRecoltePage.dart';
import 'package:agri_tech_app/ecrans/Récolte/ajout_recolte.dart';
import 'package:agri_tech_app/ecrans/Récolte/RecoltePage.dart';
import 'package:agri_tech_app/ecrans/cooperative/VentesCollectivesPage.dart';
import 'package:agri_tech_app/ecrans/cooperative/AjoutVentePage.dart';


Map<String, WidgetBuilder> routes = {
  '/': (context) => PageBienvenue(), 
  '/connexion': (context) => EcranConnexion(),
  '/inscription': (context) => PageInscription(), 
  '/reinitialisation-mdp': (context) => EcranReinitialisationMotDePasse(),
  '/ecran_accueil': (context) => PageAccueil(),
  '/PageProfil': (context) => PageProfil(),
  '/PageModifierProfil': (context) => PageModifierProfil(),
  '/UtilisateurProfil': (context) => UtilisateurProfil(),
  '/conseils': (context) => const ConseilsPage(),
  '/ajoutConseil': (context) => const AjoutConseilPage(),
  '/accueil_agriculteur': (context) => PageAccueil(),
  '/ajout_membre': (context) => const AjoutMembrePage(),
  '/membres': (context) => const ListeMembresPage(),
  '/detail_recolte': (context) =>DetailRecoltePage(),
  '/editRecolte': (context) => EditRecoltePage(),
  '/AjouterRecoltesPage' : (context) => AjoutRecoltesPage(),
  '/ventesCollectives': (context) => VentesCollectivesPage(), 
  '/venteGroupee': (context) => VenteGroupeePage(),





};
