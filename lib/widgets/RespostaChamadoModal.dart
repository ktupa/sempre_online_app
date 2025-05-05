// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../services/ixc_api_service.dart';

// class RespostaChamadoModal extends StatefulWidget {
//   final String idChamado;
//   final String tokenChamado;

//   const RespostaChamadoModal({
//     Key? key,
//     required this.idChamado,
//     required this.tokenChamado,
//   }) : super(key: key);

//   @override
//   State<RespostaChamadoModal> createState() => _RespostaChamadoModalState();
// }

// // class _RespostaChamadoModalState extends State<RespostaChamadoModal> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _mensagemController = TextEditingController();
// //   bool _isLoading = false;

// //   void _enviarResposta() async {
// //     if (!_formKey.currentState!.validate()) return;

// //     setState(() => _isLoading = true);

// //     try {
// //       await responderChamado(
// //         idChamado: widget.idChamado,
// //         tokenChamado: widget.tokenChamado,
// //         mensagem: _mensagemController.text.trim(),
// //       );
// //       Get.back();
// //       Get.snackbar(
// //         'Sucesso',
// //         'Mensagem enviada com sucesso!',
// //         backgroundColor: Colors.green,
// //         colorText: Colors.white,
// //         snackPosition: SnackPosition.BOTTOM,
// //       );
// //     } catch (e) {
// //       Get.snackbar(
// //         'Erro',
// //         'Falha ao enviar mensagem: $e',
// //         backgroundColor: Colors.redAccent,
// //         colorText: Colors.white,
// //         snackPosition: SnackPosition.BOTTOM,
// //       );
// //     } finally {
// //       setState(() => _isLoading = false);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return AlertDialog(
// //       title: const Text('Responder Chamado'),
// //       content: Form(
// //         key: _formKey,
// //         child: TextFormField(
// //           controller: _mensagemController,
// //           decoration: const InputDecoration(
// //             labelText: 'Mensagem',
// //             hintText: 'Digite sua resposta aqui...',
// //           ),
// //           maxLines: 5,
// //           validator:
// //               (value) =>
// //                   value == null || value.isEmpty ? 'Digite sua resposta' : null,
// //         ),
// //       ),
// //       actions: [
// //         TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
// //         ElevatedButton(
// //           onPressed: _isLoading ? null : _enviarResposta,
// //           child:
// //               _isLoading
// //                   ? const SizedBox(
// //                     width: 20,
// //                     height: 20,
// //                     child: CircularProgressIndicator(strokeWidth: 2),
// //                   )
// //                   : const Text('Enviar'),
// //         ),
// //       ],
// //     );
// //   }
// // }
