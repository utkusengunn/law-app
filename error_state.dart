import 'package:flutter/material.dart';

/// Kullanıcıya ham hata mesajı göstermeden, dostane Türkçe bir hata durumu
/// ve "Tekrar Dene" aksiyonu sunar.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'Bir şeyler ters gitti. Lütfen tekrar deneyin.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ],
      ),
    );
  }
}
