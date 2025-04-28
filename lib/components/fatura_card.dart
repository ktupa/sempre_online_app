import 'package:flutter/material.dart';

class FaturaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String vencimento;
  final String status;
  final Color cor;

  final VoidCallback? onPagar;
  final VoidCallback? onCodigoBarras;
  final VoidCallback? onQrCode;
  final VoidCallback? onImprimir;

  const FaturaCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.vencimento,
    required this.status,
    required this.cor,
    this.onPagar,
    this.onCodigoBarras,
    this.onQrCode,
    this.onImprimir,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: cs.surface,
      child: Row(
        children: [
          // Faixa de cor na lateral
          Container(
            height: 200,
            width: 6,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          // Conteúdo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // título + vencimento
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: cor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          titulo,
                          style: ts.titleMedium?.copyWith(
                            color: cor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'venc. $vencimento',
                        style: ts.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // valor
                  Text(
                    'Valor',
                    style: ts.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    style: ts.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // status
                  Row(
                    children: [
                      Icon(
                        status == 'Atrasada'
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline,
                        size: 18,
                        color: cor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          status,
                          style: ts.bodySmall?.copyWith(
                            color: cor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // ações
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (onPagar != null)
                        TextButton.icon(
                          onPressed: onPagar,
                          icon: Icon(Icons.payment, color: cor),
                          label: Text('Pagar', style: TextStyle(color: cor)),
                        ),
                      if (onCodigoBarras != null)
                        TextButton.icon(
                          onPressed: onCodigoBarras,
                          icon: Icon(
                            Icons.document_scanner,
                            color: cs.onSurface.withOpacity(.7),
                          ),
                          label: Text(
                            'Barras',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                        ),
                      if (onQrCode != null)
                        TextButton.icon(
                          onPressed: onQrCode,
                          icon: Icon(
                            Icons.qr_code,
                            color: cs.onSurface.withOpacity(.7),
                          ),
                          label: Text(
                            'QR Code',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                        ),
                      if (onImprimir != null)
                        TextButton.icon(
                          onPressed: onImprimir,
                          icon: Icon(
                            Icons.print,
                            color: cs.onSurface.withOpacity(.7),
                          ),
                          label: Text(
                            'Imprimir',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
