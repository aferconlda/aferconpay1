const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

// Inicializa o Firebase Admin SDK e define a região global
admin.initializeApp();
setGlobalOptions({ region: "europe-west1" });

const db = admin.firestore();

// --- Constantes ---
const CASHIER_COMMISSION_RATE = 0.01; // 1% para operações de caixa
const QR_PAYMENT_MERCHANT_COMMISSION_RATE = 0.015; // Mantido para uso futuro

/**
 * Função auxiliar para traduzir códigos de erro em mensagens para o utilizador.
 */
function translateErrorCode(code) {
  switch (code) {
    case "unauthenticated":
      return "A sessão expirou. Por favor, faça login novamente.";
    case "invalid-argument":
      return "Os dados enviados são inválidos. Verifique os valores e tente novamente.";
    case "not-found":
      return "O utilizador (cliente, caixa ou comerciante) não foi encontrado.";
    case "failed-precondition":
      return "A operação não pôde ser concluída. Verifique o seu saldo ou o estado da conta do destinatário.";
    case "permission-denied":
        return "Não tem permissão para realizar esta operação.";
    default:
      return "Ocorreu um erro inesperado no servidor.";
  }
}

exports.createUserAccount = onCall(async (request) => {
  const { uid, email, phoneNumber, displayName, nif, referralCode } = request.data;

  if (!uid) {
    throw new HttpsError('invalid-argument', 'O UID do utilizador é obrigatório.');
  }

  const userRef = db.collection('users').doc(uid);

  try {
    await db.runTransaction(async (t) => {
      const userDoc = await t.get(userRef);
      if (userDoc.exists) {
        console.log(`Utilizador com UID ${uid} já existe no Firestore.`);
        return;
      }

      const newUser = {
        uid: uid,
        email: email,
        phoneNumber: phoneNumber,
        displayName: displayName,
        nif: nif,
        role: 'customer', // 'customer', 'cashier', 'merchant', 'admin'
        balance: { 'AOA': 0 },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isVerified: false,
        kycStatus: 'none', // none, pending, approved, rejected
        fcmToken: null, // Campo para o token de notificação
      };

      if (referralCode) {
        const referrerQuery = await db.collection('users').where('personalReferralCode', '==', referralCode).limit(1).get();
        if (!referrerQuery.empty) {
          const referrerDoc = referrerQuery.docs[0];
          newUser.referredBy = referrerDoc.id;
          const referrerRef = db.collection('users').doc(referrerDoc.id);
          const notificationRef = referrerRef.collection('notifications').doc();
          t.set(notificationRef, {
            title: 'Novo Afiliado!',
            body: `O utilizador ${displayName} juntou-se usando o seu código.`,
            read: false,
            date: admin.firestore.Timestamp.now(),
          });
        }
      }
      
      const personalCode = Math.random().toString(36).substring(2, 8).toUpperCase();
      newUser.personalReferralCode = personalCode;

      t.set(userRef, newUser);
    });

    return { status: 'success', message: 'Conta criada com sucesso no Firestore.' };
  } catch (error) {
    console.error('Erro ao criar a conta de utilizador no Firestore:', error);
    throw new HttpsError('internal', 'Não foi possível guardar os dados do utilizador.');
  }
});

// --- Funções de Caixa ---
exports.addFloat = onCall(async (request) => {
  // 1. Autenticação
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "A função deve ser chamada por um utilizador autenticado.");
  }
  const cashierId = request.auth.uid;
  const { amount } = request.data;

  // 2. Validação da Entrada
  if (!amount || typeof amount !== 'number' || amount <= 0) {
    throw new HttpsError('invalid-argument', 'O montante deve ser um número positivo.');
  }

  const cashierRef = db.collection('users').doc(cashierId);

  try {
    // 3. Transação Atómica
    await db.runTransaction(async (transaction) => {
      const cashierDoc = await transaction.get(cashierRef);
      if (!cashierDoc.exists) {
        throw new HttpsError('not-found', 'Utilizador caixa não encontrado.');
      }

      const cashierData = cashierDoc.data();

      // 4. Verificação de Role
      if (cashierData.role !== 'cashier') {
         throw new HttpsError('permission-denied', 'Apenas utilizadores do tipo Caixa podem adicionar float.');
      }

      // 5. Verificação de Saldo
      const currentBalance = cashierData.balance?.AOA || 0;
      if (currentBalance < amount) {
        throw new HttpsError('failed-precondition', 'Saldo principal insuficiente.');
      }

      // 6. Atualização dos Saldos
      transaction.update(cashierRef, {
        'balance.AOA': admin.firestore.FieldValue.increment(-amount),
        'cashierFloatBalance.AOA': admin.firestore.FieldValue.increment(amount),
      });
      
      // 7. Criação do Registo de Transação
      const transactionRef = cashierRef.collection('transactions').doc();
      const now = admin.firestore.Timestamp.now();
      transaction.set(transactionRef, {
        id: transactionRef.id,
        userId: cashierId,
        type: 'float_add',
        amount: -amount, // Negativo para o saldo principal
        description: 'Carregamento de Saldo Float',
        date: now,
        status: 'completed',
        currency: 'AOA',
        from: 'balance',
        to: 'cashierFloatBalance',
      });
    });

    // 8. Envio de Notificação
    const cashierSnap = await cashierRef.get();
    const cashierData = cashierSnap.data();
    if (cashierData && cashierData.fcmToken) {
      const message = {
        token: cashierData.fcmToken,
        notification: {
          title: 'Saldo Float Carregado',
          body: `O montante de ${amount.toFixed(2)} Kz foi adicionado ao seu saldo float.`,
        },
        android: { notification: { sound: "default" } },
        apns: { payload: { aps: { sound: "default" } } },
      };
      await admin.messaging().send(message);
    }

    return { status: 'success', message: 'Saldo float carregado com sucesso.' };

  } catch (error) {
    console.error("Erro ao adicionar float:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', translateErrorCode('internal'), error.message);
  }
});

exports.withdrawFloatToBalance = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "A autenticação é obrigatória.");
    }
    const cashierId = request.auth.uid;
    const { amount } = request.data;

    if (!amount || typeof amount !== 'number' || amount <= 0) {
        throw new HttpsError('invalid-argument', 'O montante deve ser um número positivo.');
    }

    const cashierRef = db.collection('users').doc(cashierId);

    try {
        await db.runTransaction(async (transaction) => {
            const cashierDoc = await transaction.get(cashierRef);
            if (!cashierDoc.exists) {
                throw new HttpsError('not-found', 'Utilizador caixa não encontrado.');
            }

            const cashierData = cashierDoc.data();
            if (cashierData.role !== 'cashier') {
                throw new HttpsError('permission-denied', 'Apenas caixas podem realizar esta operação.');
            }

            const currentFloatBalance = cashierData.cashierFloatBalance?.AOA || 0;
            if (currentFloatBalance < amount) {
                throw new HttpsError('failed-precondition', 'Saldo flutuante insuficiente.');
            }

            // Atualiza os saldos
            transaction.update(cashierRef, {
                'cashierFloatBalance.AOA': admin.firestore.FieldValue.increment(-amount),
                'balance.AOA': admin.firestore.FieldValue.increment(amount),
            });

            // Cria o registo da transação
            const transactionRef = cashierRef.collection('transactions').doc();
            transaction.set(transactionRef, {
                id: transactionRef.id,
                userId: cashierId,
                type: 'float_withdraw',
                amount: amount, // Positivo para o saldo principal
                description: 'Levantamento de Saldo Float para Saldo Principal',
                date: admin.firestore.Timestamp.now(),
                status: 'completed',
                currency: 'AOA',
                from: 'cashierFloatBalance',
                to: 'balance',
            });
        });

        return { status: 'success', message: 'Saldo flutuante transferido para o saldo principal com sucesso.' };
    } catch (error) {
        console.error("Erro ao levantar saldo float:", error);
        if (error instanceof HttpsError) {
            throw error;
        }
        throw new HttpsError('internal', 'Ocorreu um erro interno ao processar o seu pedido.');
    }
});


// --- Funções de Pagamento e Transferência ---

exports.processQrPayment = onCall(async (request) => {
  const { auth, data } = request;
  if (!auth) throw new HttpsError("unauthenticated");

  const customerId = auth.uid;
  const { recipientId, amount, description } = data;

  if (!recipientId || typeof recipientId !== 'string' || !amount || typeof amount !== 'number' || amount <= 0) {
    throw new HttpsError("invalid-argument");
  }
  if (customerId === recipientId) {
    throw new HttpsError("invalid-argument", "Não pode fazer um pagamento a si mesmo.");
  }

  const customerRef = db.collection("users").doc(customerId);
  const recipientRef = db.collection("users").doc(recipientId);

  try {
    await db.runTransaction(async (t) => {
      const [customerDoc, recipientDoc] = await t.getAll(customerRef, recipientRef);

      if (!customerDoc.exists || !recipientDoc.exists) {
        throw new HttpsError("not-found");
      }

      const customerData = customerDoc.data();

      if ((customerData.balance?.AOA || 0) < amount) {
        throw new HttpsError("failed-precondition", `Saldo insuficiente. Saldo atual: ${(customerData.balance?.AOA || 0).toFixed(2)} Kz`);
      }
      
      const commission = 0;
      const amountReceived = amount;

      t.update(customerRef, { "balance.AOA": admin.firestore.FieldValue.increment(-amount) });
      t.update(recipientRef, { "balance.AOA": admin.firestore.FieldValue.increment(amountReceived) });

      const now = admin.firestore.Timestamp.now();
      const baseTransaction = { date: now, status: "completed", currency: "AOA" };

      const customerTransactionRef = customerRef.collection("transactions").doc();
      t.set(customerTransactionRef, {
        ...baseTransaction, id: customerTransactionRef.id, userId: customerId, type: "qr_payment_out",
        description: description || `Pagamento para ${recipientDoc.data().displayName || "Destinatário"}`,
        amount: -amount, relatedTo: recipientId,
      });

      const recipientTransactionRef = recipientRef.collection("transactions").doc();
      t.set(recipientTransactionRef, {
        ...baseTransaction, id: recipientTransactionRef.id, userId: recipientId, type: "qr_payment_in",
        description: `Pagamento recebido de ${customerData.displayName || "Cliente"}`,
        amount: amount, relatedTo: customerId, commission: commission, netAmount: amountReceived,
      });
    });

    // --- Lógica de Notificações (In-App e Push) ---

    const customerSnap = await customerRef.get();
    const recipientSnap = await recipientRef.get();
    const customerData = customerSnap.data();
    const recipientData = recipientSnap.data();

    const customerName = customerData.displayName || "Cliente";
    const recipientName = recipientData.displayName || "Destinatário";
    const notificationDate = admin.firestore.Timestamp.now();

    // 1. Notificações In-App (para histórico na app)
    const inAppBatch = db.batch();
    inAppBatch.set(customerRef.collection("notifications").doc(), {
      title: "Pagamento Concluído",
      body: `Pagamento de ${amount.toFixed(2)} Kz para ${recipientName} efetuado com sucesso.`,
      read: false, date: notificationDate,
    });
    inAppBatch.set(recipientRef.collection("notifications").doc(), {
      title: "Pagamento Recebido",
      body: `Recebeu um pagamento de ${amount.toFixed(2)} Kz de ${customerName}.`,
      read: false, date: notificationDate,
    });
    await inAppBatch.commit();

    // 2. Notificações Push (para o telemóvel)
    const pushPromises = [];
    if (recipientData.fcmToken) {
        pushPromises.push(admin.messaging().send({
            token: recipientData.fcmToken,
            notification: { title: "Pagamento Recebido", body: `Recebeu um pagamento de ${amount.toFixed(2)} Kz de ${customerName}.` },
            android: { notification: { sound: "default" } },
            apns: { payload: { aps: { sound: "default" } } },
        }));
    }
    if (customerData.fcmToken) {
        pushPromises.push(admin.messaging().send({
            token: customerData.fcmToken,
            notification: { title: "Pagamento Concluído", body: `Pagamento de ${amount.toFixed(2)} Kz para ${recipientName} efetuado com sucesso.` },
            android: { notification: { sound: "default" } },
            apns: { payload: { aps: { sound: "default" } } },
        }));
    }
    await Promise.all(pushPromises).catch(err => console.error("Falha ao enviar notificações push:", err));

    return { status: "success", message: "Pagamento concluído com sucesso." };

  } catch (error) {
    console.error("processQrPayment falhou:", error);
    if (error instanceof HttpsError) {
      throw new HttpsError(error.code, translateErrorCode(error.code), error.details);
    }
    throw new HttpsError("internal", translateErrorCode("internal"));
  }
});

exports.p2pTransfer = onCall(async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "A função deve ser chamada por um utilizador autenticado.");
  }

  const senderId = auth.uid;
  const { recipientId, recipientPhone, amount, description } = data;

  if ((!recipientId && !recipientPhone) || (recipientId && recipientPhone)) {
    throw new HttpsError("invalid-argument", "Forneça exatamente um dos seguintes: 'recipientId' ou 'recipientPhone'.");
  }
  if (!amount || typeof amount !== 'number' || amount <= 0) {
    throw new HttpsError("invalid-argument", "O 'amount' deve ser um número positivo.");
  }

  let finalRecipientId;
  const usersRef = db.collection("users");

  try {
    if (recipientPhone) {
      if (typeof recipientPhone !== 'string') {
        throw new HttpsError("invalid-argument", "O 'recipientPhone' deve ser uma string.");
      }
      const querySnapshot = await usersRef.where("phoneNumber", "==", recipientPhone).limit(1).get();
      if (querySnapshot.empty) {
        throw new HttpsError("not-found", `Nenhum utilizador encontrado com o número de telemóvel ${recipientPhone}.`);
      }
      finalRecipientId = querySnapshot.docs[0].id;
    } else {
      if (typeof recipientId !== 'string'){
        throw new HttpsError("invalid-argument", "O 'recipientId' deve ser uma string.");
      }
      finalRecipientId = recipientId;
    }

    if (senderId === finalRecipientId) {
      throw new HttpsError("invalid-argument", "O remetente e o destinatário não podem ser a mesma pessoa.");
    }

    const senderRef = usersRef.doc(senderId);
    const recipientRef = usersRef.doc(finalRecipientId);

    await db.runTransaction(async (transaction) => {
      const senderDoc = await transaction.get(senderRef);
      const recipientDoc = await transaction.get(recipientRef);

      if (!senderDoc.exists || !recipientDoc.exists) {
        throw new HttpsError("not-found", "Utilizador remetente ou destinatário não encontrado.");
      }

      const senderData = senderDoc.data();
      const recipientData = recipientDoc.data();

      const senderBalance = senderData.balance.AOA || 0;
      if (senderBalance < amount) {
        throw new HttpsError("failed-precondition", "Fundos insuficientes para esta transferência.");
      }

      transaction.update(senderRef, { "balance.AOA": admin.firestore.FieldValue.increment(-amount) });
      transaction.update(recipientRef, { "balance.AOA": admin.firestore.FieldValue.increment(amount) });

      const now = admin.firestore.Timestamp.now();
      const baseDetails = { date: now, status: "completed", currency: "AOA" };

      const senderTransactionRef = senderRef.collection("transactions").doc();
      transaction.set(senderTransactionRef, {
        ...baseDetails, id: senderTransactionRef.id, userId: senderId, type: "transfer_out",
        description: description || `Transferência para ${recipientData.displayName || "utilizador"}`,
        amount: -Math.abs(amount), relatedTo: finalRecipientId,
      });

      const recipientTransactionRef = recipientRef.collection("transactions").doc();
      transaction.set(recipientTransactionRef, {
        ...baseDetails, id: recipientTransactionRef.id, userId: finalRecipientId, type: "transfer_in",
        description: `Recebido de ${senderData.displayName || "utilizador"}`,
        amount: Math.abs(amount), relatedTo: senderId,
      });
    });

    const senderSnap = await senderRef.get();
    const recipientSnap = await recipientRef.get();
    const senderData = senderSnap.data();
    const recipientData = recipientSnap.data();

    const senderName = senderData.displayName || "Um utilizador";
    const recipientName = recipientData.displayName || "Um utilizador";
    const notificationDate = admin.firestore.Timestamp.now();

    const inAppBatch = db.batch();
    inAppBatch.set(senderRef.collection("notifications").doc(), {
      title: "Transferência Enviada",
      body: `Você enviou ${amount.toFixed(2)} AOA para ${recipientName}.`,
      read: false, date: notificationDate,
    });
    inAppBatch.set(recipientRef.collection("notifications").doc(), {
      title: "Transferência Recebida",
      body: `Você recebeu ${amount.toFixed(2)} AOA de ${senderName}.`,
      read: false, date: notificationDate,
    });
    await inAppBatch.commit();

    const pushPromises = [];
    if (recipientData.fcmToken) {
        pushPromises.push(admin.messaging().send({
            token: recipientData.fcmToken,
            notification: { title: "Transferência Recebida", body: `Você recebeu ${amount.toFixed(2)} AOA de ${senderName}.` },
            android: { notification: { sound: "default" } },
            apns: { payload: { aps: { sound: "default" } } },
        }));
    }
    if (senderData.fcmToken) {
        pushPromises.push(admin.messaging().send({
            token: senderData.fcmToken,
            notification: { title: "Transferência Enviada", body: `Você enviou ${amount.toFixed(2)} AOA para ${recipientName}.` },
            android: { notification: { sound: "default" } },
            apns: { payload: { aps: { sound: "default" } } },
        }));
    }
    await Promise.all(pushPromises).catch(err => console.error("Falha ao enviar notificações push:", err));

    return { status: "success", message: "Transferência concluída com sucesso." };

  } catch (error) {
    console.error("p2pTransfer falhou:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", translateErrorCode(error.code) || "Ocorreu um erro inesperado durante a transferência.", error.message);
  }
});

//--- NOVAS FUNÇÕES DE DEPÓSITO E LEVANTAMENTO ---

exports.processClientDeposit = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "A autenticação é necessária.");
    }
    const cashierId = request.auth.uid;
    const { clientId, amount } = request.data;

    if (!clientId || !amount || typeof amount !== 'number' || amount <= 0) {
        throw new HttpsError("invalid-argument", "Dados da transação inválidos.");
    }

    const cashierRef = db.collection("users").doc(cashierId);
    const clientRef = db.collection("users").doc(clientId);
    const commission = amount * CASHIER_COMMISSION_RATE;

    try {
        await db.runTransaction(async (t) => {
            const [cashierDoc, clientDoc] = await t.getAll(cashierRef, clientRef);

            if (!cashierDoc.exists || !clientDoc.exists) {
                throw new HttpsError("not-found", "Utilizador (caixa ou cliente) não encontrado.");
            }

            const cashierData = cashierDoc.data();
            if (cashierData.role !== 'cashier') {
                throw new HttpsError("permission-denied", "Apenas um caixa pode processar depósitos.");
            }

            const cashierFloat = cashierData.cashierFloatBalance?.AOA || 0;
            if (cashierFloat < amount) {
                throw new HttpsError("failed-precondition", "O saldo flutuante do caixa é insuficiente.");
            }

            // Movimentação de fundos
            t.update(cashierRef, { 
                "cashierFloatBalance.AOA": admin.firestore.FieldValue.increment(-amount),
                "balance.AOA": admin.firestore.FieldValue.increment(commission) // Adiciona comissão ao saldo principal do caixa
            });
            t.update(clientRef, { "balance.AOA": admin.firestore.FieldValue.increment(amount) });

            // Registos de transação
            const now = admin.firestore.Timestamp.now();
            const clientTransactionRef = clientRef.collection("transactions").doc();
            t.set(clientTransactionRef, {
                id: clientTransactionRef.id,
                type: "cash_deposit",
                amount: amount,
                description: `Depósito em numerário com ${cashierData.displayName || "Caixa"}`,
                date: now, status: "completed", currency: "AOA",
                relatedTo: cashierId
            });

            const cashierTransactionRef = cashierRef.collection("transactions").doc();
            t.set(cashierTransactionRef, {
                id: cashierTransactionRef.id,
                type: "client_deposit_processed",
                amount: -amount,
                description: `Depósito processado para ${clientDoc.data().displayName || "Cliente"}`,
                date: now, status: "completed", currency: "AOA",
                relatedTo: clientId,
                commission: commission
            });
        });

        // Lógica de notificações (adaptado do p2pTransfer)
        // ... (pode ser adicionado aqui se necessário)

        return { status: "success", message: "Depósito processado com sucesso." };
    } catch (error) {
        console.error("Erro ao processar depósito:", error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", translateErrorCode(error.code));
    }
});

exports.processClientWithdrawal = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "A autenticação é necessária.");
    }
    const cashierId = request.auth.uid;
    const { clientId, amount } = request.data;

    if (!clientId || !amount || typeof amount !== 'number' || amount <= 0) {
        throw new HttpsError("invalid-argument", "Dados da transação inválidos.");
    }
    
    const cashierRef = db.collection("users").doc(cashierId);
    const clientRef = db.collection("users").doc(clientId);
    const commission = amount * CASHIER_COMMISSION_RATE;

    try {
        await db.runTransaction(async (t) => {
            const [cashierDoc, clientDoc] = await t.getAll(cashierRef, clientRef);

            if (!cashierDoc.exists || !clientDoc.exists) {
                throw new HttpsError("not-found", "Utilizador (caixa ou cliente) não encontrado.");
            }

            const cashierData = cashierDoc.data();
            const clientData = clientDoc.data();

            if (cashierData.role !== 'cashier') {
                throw new HttpsError("permission-denied", "Apenas um caixa pode processar levantamentos.");
            }

            const clientBalance = clientData.balance?.AOA || 0;
            if (clientBalance < amount) {
                throw new HttpsError("failed-precondition", "O saldo do cliente é insuficiente.");
            }

            // Movimentação de fundos
            t.update(clientRef, { "balance.AOA": admin.firestore.FieldValue.increment(-amount) });
            t.update(cashierRef, { 
                "cashierFloatBalance.AOA": admin.firestore.FieldValue.increment(amount),
                "balance.AOA": admin.firestore.FieldValue.increment(commission) // Adiciona comissão ao saldo principal do caixa
            });
            
            // Registos de transação
            const now = admin.firestore.Timestamp.now();
            const clientTransactionRef = clientRef.collection("transactions").doc();
            t.set(clientTransactionRef, {
                id: clientTransactionRef.id,
                type: "cash_withdrawal",
                amount: -amount,
                description: `Levantamento em numerário com ${cashierData.displayName || "Caixa"}`,
                date: now, status: "completed", currency: "AOA",
                relatedTo: cashierId
            });

            const cashierTransactionRef = cashierRef.collection("transactions").doc();
            t.set(cashierTransactionRef, {
                id: cashierTransactionRef.id,
                type: "client_withdrawal_processed",
                amount: amount,
                description: `Levantamento processado para ${clientDoc.data().displayName || "Cliente"}`,
                date: now, status: "completed", currency: "AOA",
                relatedTo: clientId,
                commission: commission
            });
        });

        // Lógica de notificações (adaptado do p2pTransfer)
        // ... (pode ser adicionado aqui se necessário)

        return { status: "success", message: "Levantamento processado com sucesso." };
    } catch (error) {
        console.error("Erro ao processar levantamento:", error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", translateErrorCode(error.code));
    }
});
