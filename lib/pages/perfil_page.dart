// lib/pages/perfil_page.dart
//
// Mesma página anterior, **sem remover nada**, apenas adicionando o
// mapeamento dos códigos-de-cidade para nomes amigáveis.
//
// ⚠️  Se precisar acrescentar mais cidades depois, basta incluir novos
//      `case` dentro de `_mapCidade`.

import 'package:flutter/material.dart';
import '../services/ixc_api_service.dart';
import '../services/auth_service.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({Key? key}) : super(key: key);

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late Future<Map<String, dynamic>> _futureProfile;
  final _phoneCtrl = TextEditingController();
  final _whatsCtrl = TextEditingController();
  late String _cpf;
  late String _clienteId;

  /* ---------- mapeia alguns IDs de cidade ---------- */
  String _mapCidade(dynamic valor) {
    final id = valor?.toString() ?? '';
    switch (id) {
      case '5412':
        return 'Goiânia';
      case '5390':
        return 'Crixás';
      case '5438':
        return 'Itapuranga';
      case '5527':
        return 'Santa Terezinha de Goiás';
      case '5554':
        return 'Uirapuru';
      default:
        return id; // se não encontrar, devolve o valor original
    }
  }

  /* ---------- ciclo de vida ---------- */
  @override
  void initState() {
    super.initState();
    final user = AuthService().clientData!;
    _cpf = user['cnpj_cpf'];
    _clienteId = user['id'].toString();
    _loadProfile();
  }

  void _loadProfile() {
    _futureProfile = buscarClientePorCpf(_cpf).then((p) {
      if (p != null) {
        _phoneCtrl.text = p['telefone_celular'] ?? '';
        _whatsCtrl.text = p['whatsapp'] ?? '';
      }
      return p ?? <String, dynamic>{};
    });
  }

  void _save() async {
    await atualizarCliente(
      _clienteId,
      telefoneCelular: _phoneCtrl.text.trim(),
      whatsapp: _whatsCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: const Text('Perfil atualizado com sucesso!'),
      ),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _whatsCtrl.dispose();
    super.dispose();
  }

  /* ---------- UI ---------- */
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureProfile,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final p = snap.data!;
          final nome = p['razao'] ?? 'Sem Nome';
          final email = p['email'] ?? 'Sem Email';
          final endereco = p['endereco'] ?? 'Sem Endereço';
          final numero = p['numero'] ?? 'S/N';
          final bairro = p['bairro'] ?? 'Sem Bairro';
          final cidade = _mapCidade(p['cidade']); // <-- mapeamento aqui
          final complemento = p['complemento'] ?? '';
          final cadastro = p['data_cadastro'] ?? '—';

          return CustomScrollView(
            slivers: [
              _buildHeader(nome, email, cs),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle('Dados do Cliente', ts, cs),
                    _buildInfoTile(
                      'Endereço',
                      '$endereco, Nº $numero',
                      Icons.home,
                    ),
                    _buildInfoTile('Bairro', bairro, Icons.location_city),
                    _buildInfoTile(
                      'Complemento',
                      complemento.isNotEmpty ? complemento : '—',
                      Icons.add_location_alt_outlined,
                    ),
                    _buildInfoTile('Cidade', cidade, Icons.location_on),
                    _buildInfoTile('Data Cadastro', cadastro, Icons.date_range),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Contatos', ts, cs),
                    _buildEditableField(
                      _phoneCtrl,
                      'Telefone Celular',
                      Icons.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableField(_whatsCtrl, 'WhatsApp', Icons.message),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String nome, String email, ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // ➋
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Text(
                  nome.isNotEmpty
                      ? nome.split(' ').map((e) => e[0]).take(2).join()
                      : '',
                  style: const TextStyle(fontSize: 32, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),

              // ➊ Container para assumir largura máxima
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  nome,
                  textAlign: TextAlign.center, // ➌
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 2),
              Text(
                email,
                textAlign: TextAlign.center, // também pode centrar o email
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, TextTheme ts, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: ts.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: cs.onBackground,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title, style: ts.bodyMedium),
        subtitle: Text(
          value,
          style: ts.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: cs.primary),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text('Salvar Alterações'),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          if (_phoneCtrl.text.trim().isEmpty ||
              _whatsCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preencha todos os campos de contato.'),
              ),
            );
          } else {
            _save();
          }
        },
      ),
    );
  }
}
