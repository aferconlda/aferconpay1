class CurrencyService {

  // Moedas que o utilizador pode ter na sua carteira para vender
  Future<List<String>> getSellableCurrencies() async {
    return [
      'USDT',
      'BTC',
      'ETH',
      'AFERCON', // A nossa própria moeda
    ];
  }

  // Moedas fiduciárias ou locais que o utilizador pode querer receber em troca
  Future<List<String>> getBuyableCurrencies() async {
    return [
      'AOA', // Kwanza Angolano
      'USD', // Dólar Americano
      'EUR', // Euro
      'BRL', // Real Brasileiro
    ];
  }

}
