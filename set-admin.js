
// Importa as bibliotecas necessárias do Firebase Admin SDK
const admin = require('firebase-admin');

// --- PASSO IMPORTANTE: Configure com as suas credenciais ---
// Descarregue o seu ficheiro de chave de serviço da consola do Firebase
// e coloque-o na raiz do projeto com o nome 'serviceAccountKey.json'
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Pega o UID do utilizador e o cargo a partir dos argumentos da linha de comando
const uid = process.argv[2];
const role = process.argv[3];

if (!uid || !role) {
  console.error('Erro: É necessário fornecer o UID do utilizador e um cargo (admin ou cashier) como argumentos.');
  console.log('Uso: node set-admin.js <UID_DO_UTILIZADOR> <CARGO>');
  process.exit(1);
}

if (role !== 'admin' && role !== 'cashier') {
    console.error('Erro: O cargo especificado é inválido. Use "admin" ou "cashier".');
    process.exit(1);
}

// Define a "custom claim" para o cargo do utilizador especificado
let claims = {};
claims[role] = true;

admin.auth().setCustomUserClaims(uid, claims)
  .then(() => {
    console.log(`Sucesso! O utilizador ${uid} é agora um ${role}.`);
    console.log('Pode verificar esta alteração na consola do Firebase, na secção Authentication.');
    process.exit(0);
  })
  .catch((error) => {
    console.error(`Erro ao definir o utilizador como ${role}:`, error);
    process.exit(1);
  });
