# Afercon Pay Blueprint

## Visão Geral

O Afercon Pay é uma aplicação financeira móvel concebida para fornecer aos utilizadores uma forma segura e conveniente de gerir as suas finanças. A aplicação permite aos utilizadores realizar transações P2P, gerir o seu saldo e acompanhar o seu histórico de transações. O Afercon Pay foi construído com o Flutter e tira partido do Firebase para autenticação, base de dados e outros serviços de backend.

## Estilo, Design e Funcionalidades Implementadas

### Arquitetura

*   **State Management:** Provider
*   **Backend:** Firebase (Firestore, Authentication, Cloud Messaging)
*   **Navegação:** Navigator 1.0 com AuthGate para gestão de autenticação

### Design

*   **Tema:** A aplicação utiliza um tema personalizado definido em `lib/theme/app_theme.dart` com suporte para os modos claro e escuro.
*   **UI Kit:** A interface do utilizador é construída com os widgets do Flutter Material e o pacote `flutter_screenutil` para um design responsivo.

### Funcionalidades

*   **Autenticação:**
    *   Os utilizadores podem registar-se e iniciar sessão com email e palavra-passe.
    *   O `AuthGate` gere o fluxo de autenticação, mostrando o ecrã de início de sessão ou o ecrã principal, dependendo do estado de autenticação do utilizador.
*   **Transações:**
    *   Os utilizadores podem criar, visualizar, editar e apagar transações.
    *   As transações são armazenadas no Firestore.
*   **Câmbio P2P:**
    *   Os utilizadores podem criar e visualizar ofertas de câmbio P2P.
*   **Notificações:**
    *   A aplicação integra o Firebase Cloud Messaging para notificações push.
    *   As notificações são geridas através de um `NotificationProvider`.
*   **Referências:**
    *   A aplicação inclui um `ReferralService`, o que sugere que existe um sistema de referências.

## Plano de Ação Atual

### Problema

1.  **Erro de WebSocket Inseguro:** O ambiente de desenvolvimento está a tentar estabelecer uma ligação de recarregamento a quente (hot-reload) insegura a partir de uma página segura.
2.  **Erro de Rota de Navegação:** A aplicação tenta navegar para a rota `/login` no arranque, mas esta rota não está definida.

### Solução

1.  **Erro de WebSocket Inseguro:**
    *   **Causa:** Este é um problema de configuração do ambiente de desenvolvimento, não um erro de código. O servidor de desenvolvimento precisa de ser configurado para usar uma ligação WebSocket segura (`wss://`).
    *   **Ação:** Embora eu não possa alterar diretamente a configuração do seu servidor, posso garantir que o código da aplicação está correto. Depois de corrigirmos o erro de navegação, podemos revisitar este problema se ele persistir.
2.  **Erro de Rota de Navegação:**
    *   **Causa:** O `MaterialApp` está a tentar navegar para uma rota inicial que não existe. Em vez de uma `initialRoute`, devemos usar a propriedade `home` para definir o widget inicial.
    *   **Ação:**
        1.  Examinar o ficheiro `lib/main.dart` para confirmar a configuração do `MaterialApp`.
        2.  Verificar que a propriedade `home` está corretamente definida como `AuthGate()`.
        3.  Investigar o `AuthGate` para compreender como ele lida com a navegação para os ecrãs de início de sessão e principal.
        4.  Garantir que a rota `/login` está corretamente definida no sistema de navegação da aplicação ou que o `AuthGate` não está a tentar navegar para ela de forma incorreta.
