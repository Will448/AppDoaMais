📱 Doa+ — Aplicativo de Doações Digitais                                                                                          
🔗 Repositório do projeto:                                                                                                                                      
 👉 https://github.com/Will448/AppDoaMais.git                                                                                     
🎥 Vídeo de apresentação / gravação:
 👉 

📌 Descrição Geral
O Doa+ é um aplicativo mobile desenvolvido com o objetivo de facilitar e incentivar doações, permitindo que usuários realizem contribuições de forma prática, segura e transparente. A plataforma possibilita a criação e gerenciamento de campanhas, integração com campanhas globais e geração de QR Codes para doações rápidas.
O projeto utiliza uma arquitetura moderna, integra serviços externos e implementa CRUD completo, além de autenticação segura, incluindo login com Google.

🎯 Funcionalidades Principais                                                        
👤 Autenticação de usuários


Login tradicional


Login com Google


💝 Doações


Criação de doações


Histórico de doações do usuário


📣 Campanhas


Criação, edição, listagem e exclusão de campanhas (CRUD completo)


Integração com campanhas globais via Global Giving API


📊 Insights Inteligentes


Uso da API Groq (IA) para gerar insights e análises sobre doações


🔗 QR Code


Geração de QR Codes para facilitar doações


🌐 Integrações


Supabase para autenticação e banco de dados


Render para hospedagem da API


🧩 Arquitetura organizada em models, services, screens e widgets
🏗️ Estrutura do Projeto
lib/
├── model/
│   └── qr_model.dart
├── screens/
│   ├── create_campaign.dart
│   ├── create_donation.dart
│   ├── dashboard.dart
│   ├── donation_history.dart
│   ├── edit_campaign.dart
│   ├── login.dart
│   ├── qrcode.dart
│   └── register.dart
│
├── services/
│   ├── auth_service.dart
│   ├── campaign_service.dart
│   ├── donation_service.dart
│   ├── google_auth_service.dart
│   ├── groq_service.dart
│   ├── qr_service.dart
│   └── registration_service.dart
│
└── widgets/
    └── (componentes reutilizáveis)
🧪 Operações CRUD
O sistema implementa CRUD completo para:
Usuários


Campanhas


Doações


Garantindo persistência, atualização e remoção segura dos dados.

🔐 Segurança e Autenticação
Autenticação via Supabase


Login social com Google


Controle de acesso às funcionalidades do aplicativo



🚀 Tecnologias Utilizadas
Flutter / Dart


Supabase


Render


Global Giving API


Groq API (IA para insights)


API de geração de QR Code


Git & GitHub
