import 'package:afercon_pay/models/exchange_offer_model.dart';
import 'package:afercon_pay/screens/p2p_exchange/create_offer_screen.dart';
import 'package:afercon_pay/services/p2p_exchange_service.dart';
import 'package:afercon_pay/widgets/p2p/offer_list_item.dart';
import 'package:flutter/material.dart';

class P2PMarketplaceScreen extends StatefulWidget {
  const P2PMarketplaceScreen({super.key});

  @override
  State<P2PMarketplaceScreen> createState() => _P2PMarketplaceScreenState();
}

class _P2PMarketplaceScreenState extends State<P2PMarketplaceScreen> {
  final P2PExchangeService _exchangeService = P2PExchangeService();

  OfferType? _selectedOfferType;
  String? _selectedFromCurrency;
  String? _selectedToCurrency;

  Future<void> _showFilterDialog() async {
    // In a real app, you'd get these from a config or the offers themselves
    const availableCurrencies = ['AOA', 'USD', 'EUR'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar Ofertas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<OfferType>(
                initialValue: _selectedOfferType,
                hint: const Text('Tipo de Oferta'),
                onChanged: (value) => setState(() => _selectedOfferType = value),
                items: OfferType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.name));
                }).toList(),
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedFromCurrency,
                hint: const Text('Moeda de'),
                onChanged: (value) => setState(() => _selectedFromCurrency = value),
                items: availableCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedToCurrency,
                hint: const Text('Moeda para'),
                onChanged: (value) => setState(() => _selectedToCurrency = value),
                items: availableCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedOfferType = null;
                  _selectedFromCurrency = null;
                  _selectedToCurrency = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado P2P'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<ExchangeOffer>>(
        stream: _exchangeService.getOpenOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar ofertas: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhuma oferta disponível no momento.'),
            );
          }

          var offers = snapshot.data!;

          // Apply filters
          if (_selectedOfferType != null) {
            offers = offers.where((o) => o.type == _selectedOfferType).toList();
          }
          if (_selectedFromCurrency != null) {
            offers = offers.where((o) => o.fromCurrency == _selectedFromCurrency).toList();
          }
          if (_selectedToCurrency != null) {
            offers = offers.where((o) => o.toCurrency == _selectedToCurrency).toList();
          }

          if (offers.isEmpty) {
            return const Center(child: Text('Nenhuma oferta encontrada com os filtros selecionados.'));
          }

          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return OfferListItem(offer: offers[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateOfferScreen()));
        },
        label: const Text('Criar Oferta'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
