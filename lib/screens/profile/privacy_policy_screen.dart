import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Política de Privacidade'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column( // <- CONST REMOVIDO DAQUI
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidade da Afercon Pay',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Última atualização: 24 de Julho de 2024',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            const Text(
              'A sua privacidade é extremamente importante para nós. Esta Política de Privacidade explica como a Afercon Pay ("nós", "nosso") recolhe, usa, partilha e protege as suas informações pessoais quando utiliza os nossos Serviços.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('1. Informação que Recolhemos'),
            _buildParagraph(
                'Recolhemos vários tipos de informação, incluindo:\n\n- **Informação Pessoal:** Nome, número de telemóvel, e-mail, data de nascimento, e informações do documento de identidade (BI) fornecidas durante o registo e processo KYC.\n- **Informação Financeira:** Detalhes de transações, saldo, pedidos de crédito, e informações de contas bancárias associadas.\n- **Informação Técnica:** Endereço IP, tipo de dispositivo, sistema operativo, e dados de utilização da aplicação recolhidos automaticamente quando acede aos nossos Serviços.\n- **Informação de Localização:** Podemos recolher a sua localização aproximada para segurança e prevenção de fraude.'),
            const SizedBox(height: 16),
            _buildSectionTitle('2. Como Usamos a Sua Informação'),
            _buildParagraph(
                'Utilizamos a sua informação para:\n\n- **Fornecer e Gerir os Serviços:** Processar transações, gerir a sua conta e fornecer suporte ao cliente.\n- **Verificar a sua Identidade:** Cumprir com os requisitos legais de KYC e prevenir fraudes.\n- **Melhorar os Nossos Serviços:** Analisar como os utilizadores interagem com a aplicação para melhorar a experiência e desenvolver novas funcionalidades.\n- **Comunicação:** Enviar notificações sobre transações, atualizações de segurança, e informações de marketing (das quais pode optar por sair).\n- **Segurança:** Proteger a sua conta e os nossos sistemas contra atividades fraudulentas ou ilegais.'),
            const SizedBox(height: 16),
            _buildSectionTitle('3. Partilha de Informação'),
            _buildParagraph(
                'Não vendemos as suas informações pessoais. Podemos partilhar a sua informação com terceiros apenas nas seguintes circunstâncias:\n\n- **Com o seu Consentimento:** Quando nos autoriza a partilhar a sua informação.\n- **Prestadores de Serviços:** Com empresas que nos ajudam a operar, como processadores de pagamento, serviços de verificação de identidade e fornecedores de infraestrutura cloud. Estes parceiros estão contratualmente obrigados a proteger a sua informação.\n- **Obrigações Legais:** Se formos obrigados por lei, intimação judicial ou outra ordem governamental a divulgar informações.\n- **Para Prevenção de Danos:** Se acreditarmos que a divulgação é necessária para prevenir danos físicos ou perdas financeiras, ou para reportar atividades ilegais suspeitas.'),
            const SizedBox(height: 16),
            _buildSectionTitle('4. Segurança dos Dados'),
            _buildParagraph(
                'Implementamos medidas de segurança técnicas e administrativas robustas para proteger as suas informações. Usamos encriptação (como SSL/TLS) para proteger os dados em trânsito e controlos de acesso rigorosos para proteger os dados em repouso. No entanto, nenhum sistema é 100% seguro, e não podemos garantir segurança absoluta.'),
            const SizedBox(height: 16),
            _buildSectionTitle('5. Retenção de Dados'),
            _buildParagraph(
                'Manteremos as suas informações pessoais pelo tempo necessário para cumprir os propósitos descritos nesta política, a menos que um período de retenção mais longo seja exigido ou permitido por lei. Mesmo após o encerramento da sua conta, podemos reter certas informações para cumprir com as nossas obrigações legais, resolver disputas e fazer valer os nossos acordos.'),
            const SizedBox(height: 16),
            _buildSectionTitle('6. Os Seus Direitos de Privacidade'),
            _buildParagraph(
                'Dependendo da sua jurisdição, pode ter o direito de aceder, corrigir, ou apagar as suas informações pessoais. Pode aceder e atualizar a maioria das suas informações diretamente na sua secção de Perfil. Para outros pedidos, por favor contacte o nosso suporte.'),
            const SizedBox(height: 16),
            _buildSectionTitle('7. Privacidade de Menores'),
            _buildParagraph(
                'Os nossos serviços não se destinam a menores de 18 anos. Não recolhemos intencionalmente informações pessoais de menores. Se tomarmos conhecimento de que recolhemos informações de um menor sem o consentimento parental, tomaremos medidas para remover essa informação.'),
            const SizedBox(height: 16),
            _buildSectionTitle('8. Alterações a esta Política'),
            _buildParagraph(
                'Podemos atualizar esta Política de Privacidade periodicamente. Notificá-lo-emos de quaisquer alterações significativas publicando a nova política na aplicação e atualizando a data da "última atualização".'),
            const SizedBox(height: 16),
            _buildSectionTitle('9. Contacto'),
            _buildParagraph(
                'Se tiver alguma dúvida ou preocupação sobre a nossa Política de Privacidade ou práticas de dados, por favor contacte-nos através do e-mail privacidade@aferconpay.com.'),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget _buildParagraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
    );
  }
}
