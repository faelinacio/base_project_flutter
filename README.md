# base_project_flutter

Projeto Flutter inicializado do zero com as ferramentas e práticas atuais de mercado, com
autenticação (login, cadastro e 2FA/TOTP) integrada ao backend
[base_project_spring_boot](https://github.com/faelinacio/base_project_spring_boot). Mesma
funcionalidade do [base_project_react](https://github.com/faelinacio/base_project_react), portada
para Flutter.

## Stack

- [Flutter](https://flutter.dev/) 3.x / [Dart](https://dart.dev/) 3.x — Material 3, suporte a
  Android, iOS e Web a partir do mesmo código
- [flutter_riverpod](https://riverpod.dev/) — gerenciamento de estado e injeção de dependência
- [go_router](https://pub.dev/packages/go_router) — roteamento declarativo, com rotas protegidas
- [dio](https://pub.dev/packages/dio) — cliente HTTP, com renovação automática de token
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) — persistência segura
  do refresh token (Keychain/Keystore)
- [flutter_lints](https://pub.dev/packages/flutter_lints) — lint
- `flutter_test` + [mocktail](https://pub.dev/packages/mocktail) — testes

## Estrutura de pastas

```
lib/
  main.dart       ponto de entrada (ProviderScope + App)
  app.dart        MaterialApp.router, tema e overlay de carregamento da sessão
  components/     widgets reutilizáveis de UI (TopBar, AppShell, AlertMessage, spinner)
  core/           cliente HTTP, armazenamento do token, tema, config, extração de erros da API
  models/         modelos compartilhados (espelham os DTOs do base_project_spring_boot)
  pages/          uma tela por rota
  providers/      providers Riverpod (estado de autenticação, singletons de infraestrutura)
  router/         definição das rotas (go_router) e guards de autenticação
  services/       integração com a API do base_project_spring_boot
test/             testes de unidade e de widget
```

## Autenticação e integração com o backend

O app consome a API do **base_project_spring_boot**. A URL base é configurável via
`--dart-define` (padrão `http://localhost:8080`):

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

> No emulador Android, use `http://10.0.2.2:8080` em vez de `localhost` para alcançar a máquina
> hospedeira.

No backend, para desenvolvimento local, rode com o profile `dev`
(`SPRING_PROFILES_ACTIVE=dev`), que já libera CORS para as origens usadas pelo Flutter em modo
web/debug.

Endpoints consumidos (`lib/services/`):

| Endpoint                          | Uso                                                  |
| ---------------------------------- | ---------------------------------------------------- |
| `POST /api/auth/register`         | Criação de usuário (loga automaticamente)            |
| `POST /api/auth/login`            | Login com e-mail/senha                               |
| `POST /api/auth/login/totp`       | Confirmação do login quando o 2FA está ativo         |
| `POST /api/auth/refresh`          | Renovação do par de tokens (rotação automática)      |
| `POST /api/auth/logout`           | Logout                                               |
| `GET /api/users/me`               | Perfil do usuário autenticado (inclui `totpEnabled`) |
| `POST /api/users/me/totp/setup`   | Início do cadastro de 2FA (QR code + secret)         |
| `POST /api/users/me/totp/enable`  | Confirmação e ativação do 2FA                        |
| `POST /api/users/me/totp/disable` | Desativação do 2FA                                   |

O `accessToken` é mantido em memória e o `refreshToken` em armazenamento seguro
(`flutter_secure_storage`); o cliente HTTP (`lib/core/api_client.dart`) intercepta respostas `401`
e tenta renovar o token automaticamente antes de repetir a requisição, deslogando o usuário caso a
renovação falhe.

## Telas

- **Login** (`/login`) — e-mail/senha, com etapa adicional de verificação TOTP quando a conta tem
  2FA ativo
- **Cadastro** (`/register`) — nome, e-mail e senha
- **Início** (`/`) — tela autenticada com saudação ao usuário
- **Configurações** (`/settings`) — dados do perfil e gerenciamento de 2FA (ativar com QR code,
  desativar)
- Tela de rota não encontrada para caminhos desconhecidos

## Scripts

| Comando                             | Descrição                              |
| ------------------------------------ | --------------------------------------- |
| `flutter pub get`                   | instala as dependências                 |
| `flutter run`                       | inicia o app em modo debug              |
| `flutter build web/apk/ios`         | gera o build de produção                |
| `flutter analyze`                   | executa o analisador estático (lint)    |
| `dart format lib test`              | formata os arquivos                     |
| `dart format --output=none --set-exit-if-changed lib test` | verifica a formatação sem alterar |
| `flutter test`                      | executa os testes                       |

## Como começar

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```
