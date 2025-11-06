import 'package:afercon_pay/models/exchange_offer_model.dart';
import 'package:afercon_pay/screens/p2p_exchange/p2p_transaction_screen.dart';
import 'package:flutter/material.dart';

class OfferListItem extends StatelessWidget {
  final ExchangeOffer offer;

  const OfferListItem({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  offer.offererName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                     Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => P2PTransactionScreen(offer: offer),
                      ));
                  },
                  child: const Text('COMPRAR'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Vender: '),
                  TextSpan(
                    text: '${offer.availableAmount.toStringAsFixed(2)} ${offer.fromCurrency}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
             Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Taxa de Câmbio: '),
                  TextSpan(
                    text: '${offer.rate} ${offer.toCurrency} / ${offer.fromCurrency}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('Limites: ${offer.minLimit.toStringAsFixed(2)} - ${offer.maxLimit.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: offer.paymentMethods
                  .map((method) => Chip(
                        label: Text(method, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                         visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
