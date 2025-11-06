
// Importa as bibliotecas necessárias do Firebase Admin SDK
const admin = require('firebase-admin');

// --- PASSO IMPORTANTE: Configure com as suas credenciais ---
// Descarregue o seu ficheiro de chave de serviço da consola do Firebase
// e coloque-o na raiz do projeto com o nome 'serviceAccountKey.json'
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Pega o UID do utilizador a partir dos argumentos da linha de comando
const uid = process.argv[2];

if (!uid) {
  console.error('Erro: É necessário fornecer o UID do utilizador como argumento.');
  console.log('Uso: node set-admin.js <UID_DO_UTILIZADOR>');
  process.exit(1);
}

// Define a "custom claim" de administrador para o utilizador especificado
admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log(`Sucesso! O utilizador ${uid} é agora um administrador.`);
    console.log('Pode verificar esta alteração na consola do Firebase, na secção Authentication.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Erro ao definir o utilizador como administrador:', error);
    process.exit(1);
  });
