import 'package:share_plus/share_plus.dart';
import 'package:imobareld/models/property_model.dart';


class ShareUtils {
  /// Partager une propriété immobilière
  static Future<void> shareProperty(PropertyModel property) async {
    final String price = property.price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]} '
    );

    final String message = '''
🏠 *Nouvelle annonce sur IMOBARELD !*

*${property.title}* (${property.category})
💰 Prix : $price FCFA ${property.transactionType == 'Location' ? '/ ${property.priceDuration.toLowerCase()}' : ''}
📍 Lieu : ${property.quartier}, ${property.city}
📝 ${property.description.length > 100 ? '${property.description.substring(0, 100)}...' : property.description}

🔗 Voir l'annonce complète : 
https://imobareld.app/property/${property.id}

#immobilier #imobareld #location #vente
''';

    await Share.share(message, subject: 'Annonce Immobilière : ${property.title}');
  }
}
