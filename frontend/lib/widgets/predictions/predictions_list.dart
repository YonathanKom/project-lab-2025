import 'package:fastflutter/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prediction.dart';
import '../../models/shopping_list.dart';
import '../../api/services/prediction_service.dart';
import '../../api/services/shopping_list_service.dart';
import '../../providers/auth_provider.dart';
import 'prediction_tile.dart';

class PredictionsList extends StatefulWidget {
  final ShoppingList? shoppingList;
  final VoidCallback? onItemAdded;

  const PredictionsList({
    super.key,
    this.shoppingList,
    this.onItemAdded,
  });

  @override
  State<PredictionsList> createState() => _PredictionsListState();
}

class _PredictionsListState extends State<PredictionsList> {
  late PredictionService _predictionService;
  late ShoppingListService _shoppingListService;
  PredictionsResponse? _predictions;
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _addingItems = {};

  @override
  void initState() {
    super.initState();
    _predictionService = PredictionService(baseUrl);
    _shoppingListService = ShoppingListService(baseUrl);
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      final predictions = await _predictionService.getPredictions(
        token: token,
        shoppingListId: widget.shoppingList?.id,
        limit: 10,
      );

      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load predictions';
        _isLoading = false;
      });
    }
  }

  Future<void> _addPredictionToList(
      ItemPrediction prediction, int index) async {
    if (widget.shoppingList == null) return;

    setState(() {
      _addingItems.add(index);
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      await _shoppingListService.createShoppingItem(
        listId: widget.shoppingList!.id,
        itemData: prediction.toShoppingItemData(),
        token: token,
      );

      if (!mounted) return;

      // Update UI after adding item
      setState(() {
        _predictions!.predictions.removeAt(index);
        _addingItems.remove(index);
      });

      widget.onItemAdded?.call();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${prediction.itemName} added to list'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _addingItems.remove(index);
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add ${prediction.itemName}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Update the build method in _PredictionsListState class

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadPredictions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_predictions == null || _predictions!.predictions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No predictions available',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Start shopping to get personalized suggestions!',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final predictions = _predictions!.predictions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggested Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _loadPredictions,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        // All predictions in scrollable container
        Container(
          height: 200, // Fixed height for scrollable area
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView.builder(
            itemCount: predictions.length,
            itemBuilder: (context, index) {
              final prediction = predictions[index];
              final isAdding = _addingItems.contains(index);

              return PredictionTile(
                prediction: prediction,
                isAdding: isAdding,
                onAdd: widget.shoppingList != null && !isAdding
                    ? () => _addPredictionToList(prediction, index)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
