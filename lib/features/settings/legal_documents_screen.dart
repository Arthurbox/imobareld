import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';

class LegalDocumentsScreen extends StatelessWidget {
  final bool isTermsOfService;

  const LegalDocumentsScreen({
    super.key,
    required this.isTermsOfService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTermsOfService ? 'Conditions Générales' : 'Politique de Confidentialité',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: isTermsOfService ? _buildTerms(context) : _buildPrivacy(context),
        ),
      ),
    );
  }

  List<Widget> _buildTerms(BuildContext context) {
    return [
      _buildSectionTitle(context, 'Dernière mise à jour : 19 mars 2026'),
      const SizedBox(height: 20),
      _buildArticle(context, '1. Objet des Services', 
          'Les présentes CGU définissent les règles d\'utilisation de la plateforme Imobareld. En accédant à nos services, vous acceptez sans réserve ces conditions. La plateforme facilite la mise en relation pour l\'immobilier, la location de véhicules et les services de livraison.'),
      _buildArticle(context, '2. Accès et Création de Compte', 
          'L\'accès aux fonctionnalités avancées nécessite la création d\'un compte. Vous êtes responsable du maintien de la confidentialité de vos identifiants. Imobareld se réserve le droit de refuser l\'accès à tout utilisateur ne respectant pas les présentes conditions.'),
      _buildArticle(context, '3. Propriété Intellectuelle', 
          'Tous les éléments de l\'application (textes, logos, designs, codes sources) sont la propriété exclusive d\'Imobareld ou de ses partenaires. Toute reproduction ou exploitation non autorisée est strictement interdite.'),
      _buildArticle(context, '4. Obligations et Conduite', 
          'Les utilisateurs s\'engagent à publier des informations véridiques. Il est strictement interdit de :\n- Publier des contenus frauduleux ou trompeurs.\n- Utiliser la plateforme à des fins illicites.\n- Porter atteinte à l\'intégrité technique de l\'application.'),
      _buildArticle(context, '5. Limitation de Responsabilité', 
          'Imobareld est un intermédiaire technique. Nous ne garantissons pas l\'exactitude des annonces publiées par les tiers. La société n\'est pas partie aux contrats conclus entre les utilisateurs et décline toute responsabilité en cas de litige relatif à l\'exécution de ces contrats.'),
      _buildArticle(context, '6. Modification des Conditions', 
          'Imobareld se réserve le droit de modifier les présentes CGU à tout moment. Les utilisateurs seront informés des changements significatifs via l\'application.'),
      const SizedBox(height: 40),
    ];
  }

  List<Widget> _buildPrivacy(BuildContext context) {
    return [
      _buildSectionTitle(context, 'Dernière mise à jour : 19 mars 2026'),
      const SizedBox(height: 20),
      _buildArticle(context, '1. Collecte des Données', 
          'Nous collectons les informations nécessaires au bon fonctionnement des services :\n- Informations de profil (Nom, Email, Téléphone).\n- Données de géolocalisation (uniquement avec votre consentement pour la recherche de biens et les livraisons).\n- Contenus multimédias (Photos/Vidéos téléchargées).'),
      _buildArticle(context, '2. Finalités du Traitement', 
          'Vos données sont traitées pour :\n- Gérer votre compte et vos annonces.\n- Permettre la communication entre utilisateurs.\n- Envoyer des notifications relatives à vos activités et aux nouveautés.\n- Assurer la sécurité de la plateforme.'),
      _buildArticle(context, '3. Partage et Confidentialité', 
          'Vos données personnelles ne sont jamais vendues à des tiers. Elles sont partagées uniquement avec les prestataires techniques nécessaires (ex: Firebase) ou avec les utilisateurs avec qui vous initiez une transaction.'),
      _buildArticle(context, '4. Sécurité des Données', 
          'Nous mettons en œuvre des mesures de sécurité techniques et organisationnelles pour protéger vos données contre tout accès non autorisé ou perte accidentelle.'),
      _buildArticle(context, '5. Vos Droits (RGPD/Loi Locale)', 
          'Conformément à la loi, vous disposez d\'un droit d\'accès, de rectification et de suppression de vos données. Ces droits peuvent être exercés directement depuis les paramètres de votre compte ou en nous contactant.'),
      _buildArticle(context, '6. Cookies et Cache', 
          'L\'application utilise un cache local (SQLite) pour permettre un fonctionnement hors-ligne. Vous pouvez vider ce cache à tout moment depuis les paramètres.'),
      const SizedBox(height: 40),
    ];
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildArticle(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
