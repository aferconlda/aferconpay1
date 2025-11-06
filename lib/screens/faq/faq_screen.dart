import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lista de Perguntas e Respostas
    final List<Map<String, String>> faqs = [
      // --- Perguntas Gerais ---
      {
        'question': 'O que é a Afercon Pay?',
        'answer': 'A Afercon Pay é uma carteira digital que lhe permite gerir o seu dinheiro, fazer pagamentos, transferências, solicitar crédito e muito mais, tudo a partir do seu telemóvel de forma segura e conveniente.',
      },
      {
        'question': 'A Afercon Pay é um banco?',
        'answer': 'Não, a Afercon Pay é uma Instituição Financeira não bancária que oferece serviços de pagamento e uma carteira digital. Operamos em parceria com instituições financeiras regulamentadas para garantir a segurança dos seus fundos.',
      },
      {
        'question': 'Quais são os custos de utilização da Afercon Pay?',
        'answer': 'A criação de conta é gratuita. A maioria das operações, como transferências entre utilizadores Afercon Pay, são gratuitas. Operações como levantamentos ou transferências para bancos podem ter uma pequena taxa. Consulte o nosso preçário na app para mais detalhes.',
      },
      {
        'question': 'Onde posso usar a Afercon Pay?',
        'answer': 'Pode usar a Afercon Pay para enviar dinheiro a outros utilizadores, pagar em estabelecimentos comerciais parceiros, pagar contas de serviços e muito mais. A nossa rede de parceiros está em constante crescimento.',
      },
      {
        'question': 'A aplicação está disponível em que idiomas?',
        'answer': 'De momento, a aplicação está disponível em Português. Estamos a trabalhar para adicionar mais idiomas no futuro.',
      },

      // --- Conta e Segurança ---
      {
        'question': 'Como posso criar uma conta?',
        'answer': 'Basta descarregar a aplicação, clicar em "Criar Conta" e seguir os passos. Precisará de um número de telemóvel válido e de fornecer alguns dados pessoais para verificação.',
      },
      {
        'question': 'Por que preciso de verificar a minha identidade (KYC)?',
        'answer': 'A verificação de identidade (Know Your Customer) é um requisito legal e uma medida de segurança para proteger a sua conta contra fraudes, garantir que ninguém se faz passar por si e cumprir as regulações de combate à lavagem de dinheiro.',
      },
      {
        'question': 'Os meus dados pessoais e financeiros estão seguros?',
        'answer': 'Sim. Usamos tecnologia de encriptação de ponta para proteger todas as suas informações. Os seus dados são armazenados de forma segura e nunca são partilhados com terceiros sem o seu consentimento, exceto quando exigido por lei.',
      },
      {
        'question': 'Esqueci-me da minha palavra-passe. O que faço?',
        'answer': 'No ecrã de login, clique em "Esqueci-me da palavra-passe" e siga as instruções para redefinir a sua palavra-passe através do seu número de telemóvel ou e-mail associado à conta.',
      },
      {
        'question': 'Perdi o meu telemóvel. Como posso proteger a minha conta?',
        'answer': 'Entre em contacto com o nosso suporte ao cliente o mais rápido possível através dos nossos canais de ajuda. Podemos bloquear temporariamente a sua conta para impedir qualquer acesso não autorizado.',
      },
      {
        'question': 'Posso alterar o meu número de telemóvel associado à conta?',
        'answer': 'Sim, pode solicitar a alteração do seu número de telemóvel através do perfil na aplicação. Este processo pode exigir uma nova verificação de segurança para confirmar a sua identidade.',
      },
      {
        'question': 'O que é a autenticação de dois fatores (2FA)?',
        'answer': 'É uma camada extra de segurança que exige um segundo código de verificação (além da sua palavra-passe) para aceder à sua conta. Recomendamos vivamente que ative esta funcionalidade nas definições de segurança.',
      },
      {
        'question': 'Como posso encerrar a minha conta?',
        'answer': 'Lamentamos que queira sair. Para encerrar a sua conta, por favor, entre em contacto com o nosso serviço de apoio ao cliente. Eles irão guiá-lo através do processo.',
      },

      // --- Depósitos e Levantamentos ---
      {
        'question': 'Como posso depositar dinheiro na minha conta Afercon Pay?',
        'answer': 'Pode depositar dinheiro através de transferência bancária, agentes autorizados Afercon Pay ou outros métodos de pagamento disponíveis na secção "Depositar" da aplicação.',
      },
      {
        'question': 'Quanto tempo demora um depósito a ficar disponível?',
        'answer': 'Depósitos via agentes são geralmente instantâneos. Transferências bancárias podem demorar de algumas horas a 1-2 dias úteis, dependendo do banco.',
      },
      {
        'question': 'Como posso levantar dinheiro da minha conta?',
        'answer': 'Pode levantar dinheiro num agente autorizado Afercon Pay ou transferir o saldo para a sua conta bancária associada. Ambas as opções estão disponíveis na secção "Levantar" da app.',
      },
      {
        'question': 'Existem limites para depósitos ou levantamentos?',
        'answer': 'Sim, existem limites diários e mensais por razões de segurança e regulação. Os limites dependem do nível de verificação da sua conta. Pode consultar os seus limites na secção "Perfil" ou "Limites".',
      },
      {
        'question': 'O que faço se um depósito não aparecer na minha conta?',
        'answer': 'Guarde o comprovativo da transação e aguarde o tempo de processamento normal. Se o valor não aparecer após esse período, contacte o nosso suporte com os detalhes do depósito (valor, data, método) e o comprovativo.',
      },
      {
        'question': 'Posso depositar com o cartão de crédito de outra pessoa?',
        'answer': 'Não. Por motivos de segurança, todos os depósitos devem ser feitos a partir de contas ou métodos que pertençam ao titular da conta Afercon Pay.',
      },

      // --- Transferências e Pagamentos ---
      {
        'question': 'Como envio dinheiro a outro utilizador Afercon Pay?',
        'answer': 'Vá a "Transferir", escolha "Para utilizador Afercon Pay", insira o número de telemóvel do destinatário, o valor e confirme a transação com o seu PIN ou biometria. É instantâneo e gratuito.',
      },
      {
        'question': 'É possível cancelar uma transferência?',
        'answer': 'Uma vez submetida, a transferência é processada de forma automática e, regra geral, não pode ser cancelada. Verifique sempre os dados do destinatário antes de confirmar o envio.',
      },
      {
        'question': 'O que acontece se eu enviar dinheiro para o número errado?',
        'answer': 'Se o número não pertencer a um utilizador Afercon Pay, a transação será automaticamente revertida. Se pertencer a outro utilizador, o valor será creditado na conta dele. Contacte o nosso suporte para o podermos ajudar a mediar a situação.',
      },
      {
        'question': 'Como pago numa loja com Afercon Pay?',
        'answer': 'Procure pelo código QR da Afercon Pay na loja. Na app, selecione "Pagar com QR Code", aponte a câmara para o código, insira o valor (se necessário) e confirme o pagamento.',
      },
      {
        'question': 'Posso pagar contas de água, luz ou TV?',
        'answer': 'Sim. Na secção "Pagar Contas", pode escolher o serviço que deseja pagar, inserir os dados da fatura e confirmar o pagamento diretamente do seu saldo.',
      },
      {
        'question': 'Como vejo o meu histórico de transações?',
        'answer': 'O seu histórico completo de transações está disponível no ecrã principal da aplicação. Pode filtrar por tipo de transação, data ou contacto.',
      },

      // --- Serviços de Crédito ---
      {
        'question': 'Quem pode solicitar um crédito?',
        'answer': 'Qualquer utilizador com uma conta verificada (KYC aprovado) e um bom histórico de utilização da plataforma pode candidatar-se a um dos nossos produtos de crédito.',
      },
      {
        'question': 'Que tipos de crédito estão disponíveis?',
        'answer': 'Oferecemos Crédito Pessoal, para as suas necessidades do dia a dia, e Crédito Empresarial, para ajudar a financiar pequenos negócios e empreendedores.',
      },
      {
        'question': 'Como funciona o processo de candidatura a crédito?',
        'answer': 'Na secção "Crédito", pode simular o valor e o prazo que deseja. Depois, preencha um formulário simples com os seus dados e o motivo do pedido. A nossa equipa analisará o seu pedido e receberá uma resposta em breve.',
      },
      {
        'question': 'Quanto tempo demora a aprovação do crédito?',
        'answer': 'O tempo de análise varia, mas esforçamo-nos para dar uma resposta no prazo de 24 a 48 horas úteis após a submissão do pedido.',
      },
      {
        'question': 'Qual é a taxa de juro aplicada?',
        'answer': 'As taxas de juro variam consoante o tipo de crédito (pessoal ou empresarial) e o perfil de risco do cliente. Pode ver a taxa aplicável durante a simulação do seu crédito.',
      },
      {
        'question': 'Como são feitos os pagamentos das prestações do crédito?',
        'answer': 'O valor da prestação mensal será deduzido automaticamente do saldo da sua conta Afercon Pay na data de vencimento. Certifique-se de que tem saldo suficiente para evitar multas.',
      },
      {
        'question': 'Posso liquidar o meu crédito antecipadamente?',
        'answer': 'Sim, é possível liquidar o seu empréstimo a qualquer momento. Contacte o nosso suporte para saber os passos e se existem benefícios associados ao pagamento antecipado.',
      },

      // --- Problemas Técnicos e Suporte ---
      {
        'question': 'A aplicação está lenta ou a bloquear. O que devo fazer?',
        'answer': 'Tente fechar e reabrir a aplicação. Verifique se tem a versão mais recente instalada na sua loja de aplicações (Play Store ou App Store) e se a sua ligação à internet está estável.',
      },
      {
        'question': 'Não estou a receber as notificações da app. Como resolvo?',
        'answer': 'Verifique nas definições do seu telemóvel se as notificações para a Afercon Pay estão ativadas. Verifique também nas definições da própria app se as notificações estão ligadas.',
      },
      {
        'question': 'Como posso contactar o apoio ao cliente?',
        'answer': 'Pode contactar-nos através do chat de suporte dentro da aplicação, por e-mail para ajuda@aferconpay.com ou através do nosso número de telefone disponível na secção "Ajuda".',
      },
      {
        'question': 'O que é um "ID de Transação"?',
        'answer': 'É um código único para cada operação que realiza (depósito, transferência, pagamento). Se precisar de suporte para uma transação específica, fornecer este ID ajuda-nos a localizar a operação rapidamente.',
      },
      {
        'question': 'A aplicação diz que estou offline, mas tenho internet. Porquê?',
        'answer': 'Isto pode acontecer devido a uma instabilidade na rede ou a uma restrição do seu provedor. Tente mudar de Wi-Fi para dados móveis (ou vice-versa) ou reiniciar o seu telemóvel.',
      },
      {
        'question': 'Como posso atualizar a aplicação?',
        'answer': 'Vá à Google Play Store ou à Apple App Store, procure por "Afercon Pay" e toque em "Atualizar" se houver uma nova versão disponível.',
      },

      // --- Questões Adicionais ---
      {
        'question': 'Posso ter mais do que uma conta Afercon Pay?',
        'answer': 'Não. Para garantir a segurança e cumprir as regulações, cada utilizador pode ter apenas uma conta pessoal, associada ao seu NIF e documento de identidade.',
      },
      {
        'question': 'A Afercon Pay oferece cartões físicos?',
        'answer': 'Atualmente, operamos como uma carteira 100% digital. Estamos a explorar a possibilidade de oferecer cartões físicos no futuro e anunciaremos assim que estiverem disponíveis.',
      },
      {
        'question': 'Como posso sugerir uma nova funcionalidade?',
        'answer': 'Adoramos receber feedback dos nossos utilizadores! Pode enviar as suas sugestões diretamente para a nossa equipa de suporte através do chat na app ou por e-mail.',
      },
      {
        'question': 'Existe um programa de referência de amigos?',
        'answer': 'Sim! Temos um programa "Convide e Ganhe". Na secção de perfil, encontrará o seu código de convite. Partilhe-o com amigos e ambos podem ganhar um bónus quando o seu amigo se registar e fizer a primeira transação.',
      },
      {
        'question': 'O que acontece ao meu dinheiro se a Afercon Pay deixar de existir?',
        'answer': 'O seu dinheiro está salvaguardado em contas segregadas em bancos parceiros regulados. Isto significa que o seu saldo está protegido e separado dos fundos operacionais da empresa.',
      },
      {
        'question': 'Posso usar a minha conta Afercon Pay noutro país?',
        'answer': 'Pode aceder à sua conta de qualquer lugar com internet. No entanto, os serviços como pagamentos a comerciantes e levantamentos em agentes estão, por agora, limitados a Angola.',
      },
      {
        'question': 'O que significa "saldo cativo"?',
        'answer': 'Saldo cativo refere-se a uma parte do seu saldo que está temporariamente reservada para uma operação em processamento, como um pagamento online que aguarda confirmação, e não pode ser usada para outras transações.',
      },
      {
        'question': 'Como posso ver o extrato da minha conta?',
        'answer': 'Pode gerar e descarregar extratos mensais ou por período específico na secção "Histórico" ou "Perfil" da aplicação. O extrato pode ser exportado em formato PDF.',
      },
      {
        'question': 'A minha candidatura de KYC foi rejeitada. O que faço?',
        'answer': 'A razão da rejeição será indicada na notificação. Geralmente, deve-se a fotos ilegíveis ou documentos expirados. Pode submeter novamente os documentos corretos através da aplicação.',
      },
      {
        'question': 'É possível agendar pagamentos ou transferências?',
        'answer': 'Atualmente, esta funcionalidade não está disponível, mas estamos a trabalhar para a incluir em futuras atualizações da aplicação.',
      },
    ];

    return Scaffold(
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            child: ExpansionTile(
              iconColor: theme.colorScheme.secondary,
              collapsedIconColor: theme.colorScheme.onSurface.withAlpha(179),
              title: Text(
                faqs[index]['question']!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Text(
                    faqs[index]['answer']!,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
