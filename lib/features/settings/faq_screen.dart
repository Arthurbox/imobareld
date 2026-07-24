import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'question': 'Comment créer un compte ?',
        'answer': 'Pour créer un compte, allez sur la page d\'inscription, choisissez votre profil (Locataire ou Propriétaire) et remplissez vos informations.',
      },
      {
        'question': 'Comment payer mon loyer via l\'application ?',
        'answer': 'Vous pouvez payer via Mobile Money ou Carte bancaire en sélectionnant le bien ou la réservation depuis votre espace.',
      },
      {
        'question': 'Quels sont les frais de service ?',
        'answer': 'La plateforme est gratuite pour la recherche. Des frais minimes peuvent s\'appliquer lors des transactions selon le moyen de paiement choisi.',
      },
      {
        'question': 'Comment contacter un propriétaire ?',
        'answer': 'Une fois connecté, vous pouvez utiliser la messagerie intégrée pour discuter directement avec le propriétaire d\'un bien qui vous intéresse.',
      },
      {
        'question': 'Que faire si j\'ai oublié mon mot de passe ?',
        'answer': 'Sur la page de connexion, cliquez sur "Mot de passe oublié". Un lien de réinitialisation vous sera envoyé par email.',
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('FAQ', style: TextStyle(color: Theme.of(context).primaryColor)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              iconColor: AppColors.primaryOrange,
              collapsedIconColor: Theme.of(context).iconTheme.color,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['answer']!,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
