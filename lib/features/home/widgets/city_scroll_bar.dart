import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';

class CityScrollBar extends StatelessWidget {
  final List<String> cities;
  final String selectedCity;
  final Function(String) onCitySelected;

  const CityScrollBar({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cities.length + 1, // +1 pour "Toutes les villes"
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final city = isAll ? 'Toutes les villes' : cities[index - 1];
          final isSelected = selectedCity == city;
          
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                isAll ? 'Toutes' : city,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onCitySelected(city);
              },
              selectedColor: AppColors.primaryBlue,
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryBlue : theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              showCheckmark: false,
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }
}
