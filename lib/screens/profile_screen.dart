import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../utils/validators.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';

/// Avukatın profil bilgilerini görüntüleyip düzenlediği ve çıkış
/// yapabildiği ekran.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _profileService = ProfileService();

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firmNameCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _hasError = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _firmNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
      return;
    }
    try {
      final data = await _profileService.getProfile(user.uid);
      _fullNameCtrl.text = (data?['fullName'] as String?) ?? '';
      _phoneCtrl.text = (data?['phone'] as String?) ?? '';
      _firmNameCtrl.text = (data?['firmName'] as String?) ?? '';
      _email = (data?['email'] as String?) ?? user.email;
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _authService.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await _profileService.updateProfile(
        uid: user.uid,
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        firmName: _firmNameCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri güncellendi.')),
        );
      }
    } on ProfileFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bir hata oluştu, lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _authService.signOut();
      // AuthGate, oturum kapandığında otomatik olarak giriş ekranına döner.
    } on AuthFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingState();
    if (_hasError) {
      return ErrorState(
        message: 'Profil bilgileri yüklenemedi.',
        onRetry: _loadProfile,
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: _email,
            decoration: const InputDecoration(labelText: 'E-posta'),
            enabled: false,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fullNameCtrl,
            decoration: const InputDecoration(labelText: 'Ad Soyad'),
            validator: (v) => Validators.requiredField(v, fieldName: 'Ad soyad'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Telefon'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firmNameCtrl,
            decoration: const InputDecoration(labelText: 'Büro / Firma Adı'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Kaydet'),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
