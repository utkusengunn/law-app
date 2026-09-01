import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../services/client_service.dart';
import '../services/payment_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_chip.dart';
import 'payment_form_screen.dart';

/// Tüm müvekkillerdeki ödemelerin listesi, durum filtresi ile.
class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  final _service = PaymentService();
  final _clientService = ClientService();

  PaymentStatus? _filter;
  bool _loading = true;
  bool _error = false;
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      var result = _service.getAll();
      if (_filter != null) {
        result = result.where((p) => p.effectiveStatus == _filter).toList();
      }
      result.sort((a, b) => (a.effectiveDueDate ?? a.createdAt)
          .compareTo(b.effectiveDueDate ?? b.createdAt));
      setState(() {
        _payments = result;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödemeler')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filterChip(null, 'Tümü'),
                _filterChip(PaymentStatus.waiting, 'Ödenmedi'),
                _filterChip(PaymentStatus.partial, 'Kısmen Ödendi'),
                _filterChip(PaymentStatus.paid, 'Ödendi'),
                _filterChip(PaymentStatus.overdue, 'Gecikmiş'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filterChip(PaymentStatus? status, String label) {
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = status);
          _load();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingState();
    if (_error) return ErrorState(onRetry: _load);
    if (_payments.isEmpty) {
      return const EmptyState(message: 'Henüz ödeme kaydı bulunmuyor.');
    }
    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final p = _payments[index];
        final client = _clientService.getById(p.clientId);
        final due = p.effectiveDueDate;
        final statusText = p.hasPlan
            ? '${EnumLabels.paymentStatus(p.effectiveStatus)} · Kalan ${p.remainingAmount.toStringAsFixed(2)} ${p.currency}'
            : EnumLabels.paymentStatus(p.effectiveStatus);
        return ListTile(
          leading: const Icon(Icons.payments_outlined),
          title: Text('${p.paymentType} · ${p.amount.toStringAsFixed(2)} ${p.currency}'),
          subtitle: Text(
              '${client?.displayName ?? 'Bilinmeyen müvekkil'}'
              '${due != null ? ' · Vade: ${DateFormatters.formatDate(due)}' : ''}'),
          isThreeLine: false,
          trailing: StatusChip(
            label: statusText,
            color: EnumLabels.paymentStatusColor(p.effectiveStatus),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PaymentFormScreen(
                clientId: p.clientId,
                caseId: p.caseId,
                payment: p,
              ),
            ));
            _load();
          },
        );
      },
    );
  }
}
