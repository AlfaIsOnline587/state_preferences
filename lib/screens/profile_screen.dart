import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// >> state
class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  // << favorites controller
  final _favoriteController = TextEditingController();
  // >> favorites controller
  bool _controllersInitialized = false;

  // >> initState()
  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }
  // << initState()

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.read<UserProvider>();
    if (_controllersInitialized || provider.isLoading) return;

    _nameController.text = provider.user.name;
    _emailController.text = provider.user.email;
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    // << dispose favorites controller
    _favoriteController.dispose();
    // >> dispose favorites controller
    super.dispose();
  }

  // << add favorite from profile
  Future<void> _addFavorite() async {
    final provider = context.read<UserProvider>();
    await provider.addFavorite(_favoriteController.text);
    _favoriteController.clear();
  }
  // >> add favorite from profile

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // >> _saveProfile()
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserProvider>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final emailKey = email.toLowerCase();

    final dangerous = RegExp(r'[<>]|script', caseSensitive: false);
    if (dangerous.hasMatch(name)) {
      _showError('Nama mengandung karakter yang tidak diizinkan');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final registered =
        prefs.getStringList('registered_emails') ??
        ['admin@example.com', 'test@example.com'];
    final currentEmail = provider.user.email.toLowerCase();

    if (registered.contains(emailKey) && emailKey != currentEmail) {
      _showError('Email sudah digunakan');
      return;
    }

    final updatedList = registered.where((e) => e != currentEmail).toList()
      ..add(emailKey);
    await prefs.setStringList('registered_emails', updatedList);

    await provider.updateUser(
      provider.user.copyWith(name: name, email: email, isLoggedIn: true),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );
  }
  // << _saveProfile()

  // >> _logout()
  Future<void> _logout() async {
    final provider = context.read<UserProvider>();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await provider.logout();

    if (!mounted) return;

    Navigator.pop(context);
  }
  // << _logout()

  // >> build()
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }

                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // << favorites UI
                      const SizedBox(height: 24),
                      const Text(
                        'Daftar Favorit (Hobi)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _favoriteController,
                              decoration: const InputDecoration(
                                labelText: 'Tambah favorit',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addFavorite(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addFavorite,
                            icon: const Icon(Icons.add),
                            tooltip: 'Tambah',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (provider.favorites.isEmpty)
                        const Text(
                          'Belum ada favorit',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...provider.favorites.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            title: Text(item),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Hapus',
                              onPressed: () => provider.removeFavorite(item),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // >> favorites UI
                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.amber[800]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan Keamanan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Data disimpan di SharedPreferences (plaintext). '
                                'Jangan simpan password atau data sensitif di sini. '
                                'Gunakan secure storage untuk data sensitif.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  // << build()
}
// << state
