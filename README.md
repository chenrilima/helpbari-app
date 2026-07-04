<<<<<<< HEAD
# helpbari

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
# 🩺 HelpBari

<div align="center">

<img src="docs/images/logo.png" alt="HelpBari Logo" width="180"/>

### Seu acompanhamento pós-bariátrico, de forma simples, segura e inteligente.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-In_Development-orange?style=for-the-badge)

</div>

---

# 📖 Sobre o projeto

O **HelpBari** é um aplicativo desenvolvido para auxiliar pacientes bariátricos em todas as etapas do pós-operatório.

O objetivo é centralizar informações importantes, incentivar hábitos saudáveis e tornar o acompanhamento diário muito mais simples, organizado e seguro.

O projeto foi idealizado para oferecer uma experiência moderna, intuitiva e acessível, ajudando pacientes a manterem sua rotina de cuidados após a cirurgia.

---

# ✨ Funcionalidades

- 🔐 Login e autenticação
- 👤 Cadastro de pacientes
- 📅 Acompanhamento diário
- 💧 Controle de hidratação
- 💊 Controle de medicamentos
- 🥗 Registro alimentar
- ⚖️ Evolução do peso
- 📈 Histórico de progresso
- 🔔 Lembretes inteligentes
- 📊 Dashboard com indicadores
- ☁️ Sincronização em nuvem
- 🌙 Tema claro e escuro
- 📱 Interface responsiva
- 🌎 Preparado para internacionalização

---

# 🏗 Arquitetura

O projeto segue uma arquitetura moderna baseada em **MVVM**, organizada por funcionalidades (**Feature First**), priorizando:

- Escalabilidade
- Baixo acoplamento
- Alta coesão
- Facilidade de manutenção
- Testabilidade
- Reutilização de componentes

Estrutura simplificada:

```
lib/
│
├── app/
│
├── core/
│   ├── constants/
│   ├── extensions/
│   ├── services/
│   ├── widgets/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── authentication/
│   ├── onboarding/
│   ├── home/
│   ├── profile/
│   ├── hydration/
│   ├── medications/
│   ├── nutrition/
│   ├── progress/
│   └── settings/
│
└── main.dart
```

---

# 🚀 Tecnologias

- Flutter
- Dart
- Supabase
- Riverpod
- GoRouter
- Freezed
- JSON Serializable
- Flutter Secure Storage
- Shared Preferences

---

# 🎨 Design

O projeto foi desenvolvido seguindo princípios de:

- Material Design 3
- Design System
- Componentização
- Responsividade
- Acessibilidade
- Animações suaves
- UX centrada no usuário

---

# 🔒 Segurança

- Autenticação via Supabase
- Sessão persistente
- Armazenamento seguro de credenciais
- Validação de dados
- Tratamento centralizado de erros

---

# 📦 Como executar

## Clone o projeto

```bash
git clone https://github.com/SEU_USUARIO/helpbari.git
```

Entre na pasta

```bash
cd helpbari
```

Instale as dependências

```bash
flutter pub get
```

Execute

```bash
flutter run
```

---

# ⚙️ Configuração

Crie um arquivo `.env`

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

---

# 🧪 Testes

Executar todos os testes

```bash
flutter test
```

Analisar o projeto

```bash
flutter analyze
```

Formatar

```bash
dart format .
```

---

# 📱 Plataformas

- ✅ Android
- 🚧 iOS
- 🚧 Web
- 🚧 Desktop

---

# 📈 Roadmap

- [x] Estrutura inicial
- [x] Arquitetura MVVM
- [x] Integração com Supabase
- [ ] Login com Google
- [ ] Cadastro completo
- [ ] Dashboard
- [ ] Controle de hidratação
- [ ] Controle alimentar
- [ ] Registro de medicamentos
- [ ] Histórico de evolução
- [ ] Notificações
- [ ] Backup em nuvem
- [ ] Internacionalização
- [ ] Testes automatizados
- [ ] Publicação na Google Play

---

# 🤝 Contribuição

Contribuições são bem-vindas.

1. Faça um Fork
2. Crie uma Branch

```bash
git checkout -b feature/minha-feature
```

3. Commit

```bash
git commit -m "feat: nova funcionalidade"
```

4. Push

```bash
git push origin feature/minha-feature
```

5. Abra um Pull Request

---

# 📄 Licença

Este projeto está licenciado sob a licença **MIT**.

---

# 👨‍💻 Autor

**Carlos Souza**

Flutter Developer

---

<div align="center">

### ❤️ HelpBari

**Cuidando da sua jornada após a cirurgia bariátrica.**

</div>
>>>>>>> origin/main
