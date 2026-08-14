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
          isTermsOfService
              ? 'Conditions Générales d\'Utilisation'
              : 'Politique de Confidentialité',
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

  // ═══════════════════════════════════════════════════════
  // CONDITIONS GÉNÉRALES D'UTILISATION (CGU)
  // ═══════════════════════════════════════════════════════

  List<Widget> _buildTerms(BuildContext context) {
    return [
      _buildHeader(context, 'IMOBARELD', 'Conditions Générales d\'Utilisation'),
      _buildSectionTitle(context, 'Dernière mise à jour : 14 août 2026'),
      const SizedBox(height: 8),
      _buildIntro(context,
          'Les présentes Conditions Générales d\'Utilisation (CGU) régissent l\'ensemble des relations entre la plateforme IMOBARELD et ses utilisateurs. En accédant à l\'application ou en créant un compte, vous acceptez sans réserve les présentes conditions.'),
      const SizedBox(height: 16),

      _buildArticle(context, 'Article 1 — Présentation de la Plateforme',
          'IMOBARELD est une agence immobilière digitale opérant sur le territoire du Burkina Faso. La plateforme met en relation des propriétaires souhaitant louer ou vendre des biens immobiliers avec des personnes à la recherche d\'un logement ou d\'un local commercial.\n\nLes types de biens couverts :\n- Cours communes et cours uniques\n- Boutiques et magasins\n- Appartements et studios\n- Terrains\n- Villas et maisons\n- Bureaux et locaux commerciaux\n\nIMOBARELD intervient exclusivement en qualité d\'intermédiaire agréé entre les parties.'),

      _buildArticle(context, 'Article 2 — Création de Compte et Accès',
          '2.1. Pour accéder aux fonctionnalités complètes, l\'utilisateur doit créer un compte avec des informations exactes (nom complet, email valide, numéro de téléphone).\n\n2.2. Deux types de comptes sont disponibles :\n• Compte Locataire/Acheteur : consulter les annonces, contacter l\'agence, sauvegarder des favoris.\n• Compte Propriétaire : publier des annonces après souscription à un abonnement actif.\n\n2.3. L\'utilisateur est seul responsable de la confidentialité de ses identifiants.\n\n2.4. IMOBARELD peut suspendre ou supprimer tout compte en cas de non-respect des présentes CGU.'),

      _buildArticle(context, 'Article 3 — Rôle d\'Intermédiaire et Commissions',
          '3.1. IMOBARELD agit exclusivement en qualité d\'intermédiaire immobilier. L\'agence ne loue ni ne vend directement aucun bien.\n\n3.2. Structure de la commission :\nConformément aux pratiques du marché immobilier au Burkina Faso, une commission de 50% du loyer mensuel est appliquée lors de toute transaction conclue via la plateforme.\n\nSur cette commission totale :\n• 25% reviennent à IMOBARELD (agence gestionnaire)\n• 75% sont reversés à l\'apporteur d\'affaires (démarcheur)\n\n3.3. Exemple concret :\n• Loyer mensuel : 100 000 FCFA\n• Commission totale : 50 000 FCFA\n• Part IMOBARELD : 12 500 FCFA\n• Part du démarcheur : 37 500 FCFA\n\n3.4. La commission est due dès que le bien est effectivement occupé ou la vente finalisée.\n\n3.5. Le propriétaire s\'engage à notifier IMOBARELD dans un délai de 15 jours calendaires après signature du bail ou de l\'acte de vente, et à s\'acquitter de la commission dans ce même délai.\n\n3.6. En cas de non-paiement, IMOBARELD se réserve le droit de retirer les annonces, de suspendre le compte et de recourir à toute voie de droit disponible.'),

      _buildArticle(context, 'Article 4 — Abonnements Propriétaires',
          '4.1. La publication d\'annonces est réservée aux propriétaires ayant un abonnement actif ou une période d\'essai valide.\n\n4.2. Tarifs d\'abonnement :\n• 1 mois : 2 500 FCFA\n• 3 mois : 7 000 FCFA\n• 6 mois : 12 500 FCFA\n• 12 mois : 25 000 FCFA\n\n4.3. Les paiements sont traités via GeniusPay (Orange Money, Moov Money) et sont non remboursables sauf erreur manifeste de la plateforme.\n\n4.4. À l\'expiration de l\'abonnement, les annonces sont automatiquement masquées.'),

      _buildArticle(context, 'Article 5 — Boost et Visibilité des Annonces',
          'Les propriétaires peuvent améliorer la visibilité de leurs annonces via les formules suivantes :\n• Starter : 500 FCFA — 7 jours en tête de liste\n• Standard : 1 000 FCFA — 15 jours\n• Pro : 1 500 FCFA — 30 jours\n\nLes boosts sont actifs immédiatement après paiement et non remboursables.'),

      _buildArticle(context, 'Article 6 — Obligations des Propriétaires',
          'Le propriétaire s\'engage à :\n• Publier des annonces véridiques, complètes et à jour\n• Disposer du droit légal de louer ou vendre le bien mis en annonce\n• Notifier IMOBARELD immédiatement dès qu\'un bien est pris ou vendu\n• Régler les commissions dues dans les délais impartis\n\nSont strictement interdits :\n• La publication de biens inexistants ou fictifs\n• La modification des informations pour contourner le rôle d\'intermédiaire de l\'agence\n• La publication de biens appartenant à des tiers sans leur consentement'),

      _buildArticle(context, 'Article 7 — Obligations des Locataires / Acheteurs',
          '7.1. Le locataire ou acheteur s\'engage à contacter IMOBARELD pour toute demande relative à un bien, sans chercher à établir un contact direct avec le propriétaire en contournant l\'agence.\n\n7.2. Toute tentative de court-circuiter le rôle d\'intermédiaire de l\'agence constitue une violation des présentes CGU et peut entraîner la suspension du compte.'),

      _buildArticle(context, 'Article 8 — Vérification d\'Identité',
          'Les propriétaires peuvent soumettre une demande de vérification en fournissant les documents requis. Le badge "Vérifié" est attribué après validation par l\'équipe IMOBARELD. Ce badge peut être révoqué en cas de manquement constaté.'),

      _buildArticle(context, 'Article 9 — Limitation de Responsabilité',
          'IMOBARELD est un intermédiaire et ne saurait être tenu responsable des fausses informations publiées par un propriétaire, des litiges survenant entre parties après la mise en relation, ni des pertes ou dommages indirects liés à l\'utilisation de la plateforme.'),

      _buildArticle(context, 'Article 10 — Propriété Intellectuelle',
          'Tous les éléments de l\'application IMOBARELD (nom, logo, design, code source) sont la propriété exclusive d\'IMOBARELD. Toute reproduction ou exploitation non autorisée est strictement interdite.'),

      _buildArticle(context, 'Article 11 — Droit Applicable et Contact',
          'Les présentes CGU sont soumises au droit burkinabé. Tout litige sera soumis aux tribunaux compétents de Ouagadougou.\n\nContact : afrmd05@gmail.com\nTél. : +226 57 42 89 29\nOuagadougou, Burkina Faso'),

      const SizedBox(height: 40),
    ];
  }

  // ═══════════════════════════════════════════════════════
  // POLITIQUE DE CONFIDENTIALITÉ
  // ═══════════════════════════════════════════════════════

  List<Widget> _buildPrivacy(BuildContext context) {
    return [
      _buildHeader(context, 'IMOBARELD', 'Politique de Confidentialité'),
      _buildSectionTitle(context, 'Dernière mise à jour : 14 août 2026'),
      const SizedBox(height: 8),
      _buildIntro(context,
          'La présente Politique de Confidentialité décrit comment IMOBARELD collecte, utilise et protège les données personnelles de ses utilisateurs, conformément aux lois en vigueur au Burkina Faso.'),
      const SizedBox(height: 16),

      _buildArticle(context, '1. Responsable du Traitement',
          'Agence IMOBARELD\nEmail : afrmd05@gmail.com\nTéléphone : +226 57 42 89 29\nOuagadougou, Burkina Faso'),

      _buildArticle(context, '2. Données Collectées',
          '2.1. Données fournies par l\'utilisateur :\n• Nom complet, email, numéro de téléphone\n• Photo de profil (optionnelle)\n• Documents d\'identité (pour vérification propriétaires uniquement)\n\n2.2. Données générées par l\'utilisation :\n• Annonces publiées (titre, description, photos, vidéos, GPS)\n• Messages de la messagerie intégrée\n• Favoris et historique de navigation\n• Historique des paiements\n• Token de notification push (FCM)\n\n2.3. Données techniques :\n• Informations de connexion (date, heure)\n• Données de cache local (SQLite sur l\'appareil)'),

      _buildArticle(context, '3. Finalités du Traitement',
          'Vos données sont utilisées exclusivement pour :\n• Créer et gérer votre compte\n• Permettre la publication et consultation d\'annonces\n• Faciliter la mise en relation via l\'agence\n• Traiter les paiements (GeniusPay)\n• Envoyer des notifications pertinentes\n• Vérifier l\'identité des propriétaires\n• Assurer la sécurité et la modération de la plateforme'),

      _buildArticle(context, '4. Partage des Données',
          '4.1. Vos données ne sont jamais vendues ou cédées à des tiers.\n\n4.2. Elles peuvent être partagées uniquement avec nos prestataires techniques :\n• Supabase (hébergement et base de données)\n• Firebase / Google (notifications, authentification, crashlytics)\n• GeniusPay (traitement sécurisé des paiements)\n\n4.3. Vos coordonnées ne sont jamais communiquées directement aux autres utilisateurs. Tout contact passe par l\'agence IMOBARELD.'),

      _buildArticle(context, '5. Confidentialité des Numéros de Téléphone',
          'Les numéros de téléphone des propriétaires sont strictement confidentiels et jamais affichés publiquement.\n\nLorsqu\'un utilisateur souhaite contacter un propriétaire, le numéro affiché est celui de l\'agence (+226 57 42 89 29). Seul l\'administrateur IMOBARELD a accès au numéro réel du propriétaire pour coordonner les visites.\n\nCette mesure protège les propriétaires contre le démarchage abusif et garantit le rôle d\'intermédiaire de l\'agence.'),

      _buildArticle(context, '6. Sécurité des Données',
          '• Chiffrement des communications (HTTPS/TLS)\n• Authentification sécurisée via Supabase Auth\n• Accès aux données restreint selon les rôles\n• Surveillance via Firebase Crashlytics\n• Hébergement sécurisé en Europe (Supabase) et USA (Firebase)'),

      _buildArticle(context, '7. Conservation des Données',
          '• Données actives : conservées tant que le compte est actif\n• Après suppression du compte : données de profil effacées immédiatement, annonces archivées 30 jours puis supprimées, données de transactions conservées 5 ans (obligations légales)'),

      _buildArticle(context, '8. Données des Mineurs',
          'IMOBARELD est destiné aux personnes majeures (18 ans et plus). Nous ne collectons pas sciemment de données de mineurs. Signalez tout compte de mineur à afrmd05@gmail.com.'),

      _buildArticle(context, '9. Vos Droits',
          'Vous disposez des droits suivants sur vos données :\n• Droit d\'accès et de copie\n• Droit de rectification\n• Droit à l\'effacement (suppression du compte)\n• Droit d\'opposition\n• Droit à la portabilité\n\nExercice de ces droits :\n• Dans les paramètres de votre compte\n• Par email : afrmd05@gmail.com\n• Par téléphone : +226 57 42 89 29'),

      _buildArticle(context, '10. Cache Local et Mode Hors-ligne',
          'L\'application utilise une base de données locale (SQLite) pour le fonctionnement hors-ligne. Ces données ne contiennent aucune information sensible et peuvent être supprimées depuis les paramètres de l\'application.'),

      _buildArticle(context, '11. Notifications Push',
          'Avec votre consentement, IMOBARELD peut vous envoyer des notifications via Firebase pour vous informer de nouveaux biens, messages et actualités. Vous pouvez désactiver ces notifications dans les paramètres de votre appareil.'),

      _buildArticle(context, '12. Modifications et Contact',
          'Toute modification significative de cette politique sera notifiée via l\'application.\n\nContact : afrmd05@gmail.com\nTél. : +226 57 42 89 29\nOuagadougou, Burkina Faso'),

      const SizedBox(height: 40),
    ];
  }

  // ═══════════════════════════════════════════════════════
  // WIDGETS HELPERS
  // ═══════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, String appName, String docTitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryOrange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            docTitle,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildArticle(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                left: BorderSide(color: AppColors.primaryBlue, width: 3),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
