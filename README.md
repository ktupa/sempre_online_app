# 📱 Sempre Online — Aplicativo Flutter para Provedores de Internet

**Sempre Online** é um aplicativo Flutter completo, desenvolvido para provedores de internet que desejam oferecer um painel moderno para seus clientes. Com ele, é possível acessar contratos, boletos, chamados de suporte, consumo, notificações e até realizar testes de velocidade. 

Este projeto está **pronto para uso e personalização**, integrando Firebase e a API real do sistema **IXC Provedor**.

---

## ✅ Funcionalidades Principais

- Login via CPF
- Cadastro e recuperação de senha com validação de data de nascimento
- Visualização de contratos e serviços contratados
- Abertura, acompanhamento e encerramento de chamados de suporte
- Teste de velocidade integrado
- Notificações push com suporte a envio segmentado (cidade, bairro, cliente)
- Frontend Web para envio de notificações (incluso)
- Layout moderno, responsivo e pronto para Android, iOS e Web

---

## 🧱 Arquitetura do Projeto

- **Flutter** (frontend mobile e web)
- **Firebase** (mensagens push)
- **IXC API REST** (dados do cliente, contratos, chamados, etc.)
- **Backend FastAPI** (para envio de push, se necessário)
- Modularização por páginas, serviços e widgets

---

## 🔌 Integrações

### 🔐 Autenticação (IXC)
- Validação via `/cliente/verifica_cpf`
- Criação de senha com `/cliente/atualizar_dados`
- Recuperação com validação de nascimento
- Login com CPF + senha salva no IXC

### 📡 API IXC Utilizada
- `/cliente/*` → login, validação e senha
- `/chamado/*` → listar, responder, finalizar
- `/contrato/*` → visualizar planos e produtos
- `/clientes/cidades`, `/clientes/bairros`, `/clientes` → filtros para notificações

### 🔥 Firebase
- `firebase_core`, `firebase_messaging`
- Suporte completo a FCM (Android, iOS, Web)
- Arquivo `google-services.json` incluso
- Service Worker Web incluído (`firebase-messaging-sw.js`)

---

## 🧪 Teste de Velocidade

- Serviço nativo simples (`speed_test_service.dart`)
- Mede latência, jitter e download usando ping e HTTP
- Pode ser expandido para uso com Fast.com ou Speedtest API

---

## 🚀 Instalação e Setup

### 1. Clonar o projeto
```bash
git clone https://github.com/sua-empresa/sempre_online_app.git
cd sempre_online_app

##Instalar dependências
flutter pub get


Substitua o arquivo android/app/google-services.json com o seu

Para iOS, use GoogleService-Info.plist no Xcode

Web: edite firebase-messaging-sw.js e firebase.json

## Configurar API IXC
Em lib/services/ixc_api_service.dart, defina a URL e chaves de autenticação

#  Build e Publicação
# Android

flutter build apk --release

# iOS (via Codemagic)
flutter build ios --release --no-codesign

# Web
flutter build web

🛠️ Tecnologias Usadas
Tecnologia	Função
Flutter	Framework principal
Firebase Messaging	Push Notifications
Shared Preferences	Sessão e persistência local
IXC API	Backend de autenticação e dados do cliente
FastAPI (opcional)	Envio de notificações push personalizadas


Segurança e Privacidade
O app não armazena dados sensíveis localmente

A autenticação é feita diretamente com o IXC via HTTPS

Os tokens FCM são armazenados com ID do cliente no backend (opcional)


lib/
├── main.dart
├── home_controller.dart
├── firebase_options.dart
├── pages/
│   ├── login_page.dart
│   ├── cadastro_senha_page.dart
│   ├── dashboard_page.dart
│   ├── chamados_page.dart
│   └── contracts_tab.dart
├── services/
│   ├── auth_service.dart
│   ├── ixc_api_service.dart
│   └── speed_test_service.dart
└── widgets/



📄 Licença
Este projeto está licenciado para uso comercial restrito. A revenda, redistribuição ou modificação para terceiros deve ser previamente autorizada.


🤝 Suporte
Entre em contato para dúvidas, personalizações ou implantação:

📧 noc@semppreonline.com.br
📧 ktupa13@gmail.com
🌐 https://semppreonline.com.br