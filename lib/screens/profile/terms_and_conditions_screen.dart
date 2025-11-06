import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Termos e Condições'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column( // <- CONST REMOVIDO DAQUI
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Termos e Condições de Uso da Afercon Pay',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Última atualização: 24 de Julho de 2024',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bem-vindo à Afercon Pay! Estes Termos e Condições ("Termos") governam o seu acesso e uso da nossa carteira digital e serviços associados (coletivamente, os "Serviços"). Ao criar uma conta ou usar os nossos Serviços, concorda em ficar vinculado por estes Termos.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('1. Definições'),
            _buildParagraph(
                '"Conta": A sua conta pessoal na Afercon Pay.\n"Utilizador": Qualquer pessoa que acede ou utiliza os nossos Serviços.\n"KYC (Know Your Customer)": Processo de verificação de identidade exigido por lei.'),
            const SizedBox(height: 16),
            _buildSectionTitle('2. Elegibilidade e Registo de Conta'),
            _buildParagraph(
                'Para usar os nossos Serviços, deve ter pelo menos 18 anos de idade e residir em Angola. Durante o registo, compromete-se a fornecer informações verdadeiras, precisas e completas. É sua a responsabilidade de manter a confidencialidade da sua palavra-passe e é totalmente responsável por todas as atividades que ocorram na sua Conta.'),
            const SizedBox(height: 16),
            _buildSectionTitle('3. Serviços Oferecidos'),
            _buildParagraph(
                'A Afercon Pay oferece uma carteira digital que permite:\n- Armazenar fundos.\n- Realizar transferências para outros utilizadores Afercon Pay.\n- Realizar pagamentos em comerciantes parceiros.\n- Pagar contas de serviços.\n- Solicitar depósitos e levantamentos.\n- Candidatar-se a produtos de crédito (sujeito a análise e aprovação).'),
            const SizedBox(height: 16),
            _buildSectionTitle('4. Verificação de Identidade (KYC)'),
            _buildParagraph(
                'Para cumprir com as regulamentações de combate à lavagem de dinheiro e financiamento do terrorismo, exigimos que todos os utilizadores completem o nosso processo de KYC. Contas não verificadas têm limites de transação. Ao submeter os seus documentos, garante que são autênticos e válidos.'),
            const SizedBox(height: 16),
            _buildSectionTitle('5. Taxas e Encargos'),
            _buildParagraph(
                'A criação de conta é gratuita. A maioria das transferências entre utilizadores Afercon Pay é gratuita. No entanto, certas transações, como levantamentos, pagamentos de serviços específicos ou taxas de análise de crédito, podem estar sujeitas a taxas, que serão claramente comunicadas antes de confirmar a transação.'),
            const SizedBox(height: 16),
            _buildSectionTitle('6. Conduta do Utilizador'),
            _buildParagraph(
                'Concorda em não usar os Serviços para qualquer atividade ilegal ou fraudulenta. É proibido usar a conta para fins de lavagem de dinheiro, evasão fiscal ou qualquer outra atividade que viole a lei angolana. Reservamo-nos o direito de suspender ou encerrar a sua conta se suspeitarmos de qualquer violação.'),
            const SizedBox(height: 16),
            _buildSectionTitle('7. Limitação de Responsabilidade'),
            _buildParagraph(
                'A Afercon Pay não será responsável por quaisquer perdas diretas, indiretas, incidentais ou consequenciais resultantes do uso ou da incapacidade de usar os nossos Serviços, incluindo perdas resultantes de transações não autorizadas, falhas de sistema ou outros eventos fora do nosso controlo razoável.'),
            const SizedBox(height: 16),
            _buildSectionTitle('8. Propriedade Intelectual'),
            _buildParagraph(
                'Todo o conteúdo, logótipos, e software associados aos Serviços são propriedade da Afercon ou dos seus licenciadores e estão protegidos por leis de direitos de autor e outras leis de propriedade intelectual.'),
            const SizedBox(height: 16),
            _buildSectionTitle('9. Modificações aos Termos'),
            _buildParagraph(
                'Reservamo-nos o direito de modificar estes Termos a qualquer momento. Notificá-lo-emos de quaisquer alterações através da aplicação ou por e-mail. O uso continuado dos Serviços após a data de entrada em vigor das alterações constitui a sua aceitação dos novos Termos.'),
            const SizedBox(height: 16),
            _buildSectionTitle('10. Lei Aplicável e Jurisdição'),
            _buildParagraph(
                'Estes Termos serão regidos e interpretados de acordo com as leis da República de Angola. Qualquer disputa ou reclamação resultante destes Termos será resolvida exclusivamente nos tribunais de Luanda.'),
            const SizedBox(height: 16),
            _buildSectionTitle('11. Contacto'),
            _buildParagraph(
                'Se tiver alguma dúvida sobre estes Termos, por favor contacte-nos através do e-mail suporte@aferconpay.com ou através da secção de Ajuda na aplicação.'),
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
