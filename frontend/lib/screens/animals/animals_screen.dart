import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/animals_provider.dart';
import '../../providers/auth_provider.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = ['All', 'COW', 'CATTLE', 'GOAT', 'SHEEP', 'PIG', 'CHICKEN', 'HORSE'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnimalsProvider>(context, listen: false).fetchAnimals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(child: _buildAnimalList()),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: 'Search animals...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter == 'All' ? 'All' : _formatType(filter)),
                    selected: isSelected,
                    onSelected: (selected) =>
                        setState(() => _selectedFilter = selected ? filter : _selectedFilter),
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFF13EC5B),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF102216) : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalList() {
    return Consumer<AnimalsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to Load Animals',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(provider.error!, style: TextStyle(fontSize: 13, color: Colors.red[600]), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchAnimals(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final filtered = (provider.animals as List).where((a) {
          final name = (a['name'] ?? '').toString().toLowerCase();
          final type = (a['type'] ?? '').toString().toUpperCase();
          final matchesSearch = name.contains(_searchQuery.toLowerCase());
          final matchesFilter = _selectedFilter == 'All' || type == _selectedFilter;
          return matchesSearch && matchesFilter;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No animals found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Add your first animal using the + button', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final animal = filtered[index] as Map<String, dynamic>;
            return _buildAnimalCard(animal);
          },
        );
      },
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final type = (animal['type'] ?? 'UNKNOWN').toString();
    final gender = (animal['gender'] ?? '').toString();
    final weight = animal['weight'];
    final age = animal['age'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF13EC5B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(_animalEmoji(type), style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          animal['name'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102216)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13EC5B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatType(type),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF102216)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (age != null) ...[
                        Icon(Icons.cake_outlined, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text('$age yrs', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(width: 12),
                      ],
                      if (weight != null) ...[
                        Icon(Icons.monitor_weight_outlined, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text('${weight}kg', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(width: 12),
                      ],
                      if (gender.isNotEmpty) ...[
                        Icon(
                          gender.toUpperCase() == 'MALE' ? Icons.male : Icons.female,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          gender[0].toUpperCase() + gender.substring(1).toLowerCase(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  if (animal['notes'] != null && (animal['notes'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      animal['notes'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    if (type.isEmpty) return type;
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  String _animalEmoji(String type) {
    switch (type.toUpperCase()) {
      case 'COW':
      case 'CATTLE':
        return '🐄';
      case 'GOAT':
        return '🐐';
      case 'SHEEP':
        return '🐑';
      case 'PIG':
        return '🐖';
      case 'CHICKEN':
        return '🐔';
      case 'HORSE':
        return '🐴';
      case 'DOG':
        return '🐕';
      case 'CAT':
        return '🐈';
      case 'RABBIT':
        return '🐇';
      case 'FISH':
        return '🐟';
      default:
        return '🐾';
    }
  }
}
