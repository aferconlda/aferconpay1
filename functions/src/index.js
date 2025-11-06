
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// ===================================================================
// == FUNÇÃO DE REGISTO DE UTILIZADOR (CORRIGIDA E FINAL)
// ===================================================================
exports.registerUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Apenas utilizadores autenticados podem criar registos.");
  }

  const { displayName, nif } = data;
  const uid = context.auth.uid;
  const email = context.auth.token.email;

  if (!displayName || !nif) {
    throw new functions.https.HttpsError("invalid-argument", "O 'displayName' (nome) e 'nif' são obrigatórios.");
  }

  const userRef = admin.firestore().collection("users").doc(uid);

  try {
    await userRef.set({
      displayName: displayName,
      email: email,
      nif: nif,
      uid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      balance: 0,
      commissionBalance: 0,
      floatBalance: 0,
      role: "client",
      status: "active"
    }, { merge: true }); // <-- A CORREÇÃO FINAL E DEFINITIVA

    console.log(`Documento do utilizador ${uid} criado/atualizado com sucesso para ${email}.`);
    return { status: "success", message: "Documento do utilizador processado com sucesso.", userId: uid };
  } catch (error) {
    console.error(`Erro ao processar documento para o utilizador ${uid}:`, error);
    throw new functions.https.HttpsError("internal", "Não foi possível guardar os dados do utilizador na base de dados.");
  }
});

// ===================================================================
// == FERRAMENTA DE ADMIN: FORÇAR VERIFICAÇÃO DE EMAIL
// ===================================================================
exports.forceVerifyUser = functions.https.onCall(async (data, context) => {
  // 1. Verificar se o chamador está autenticado
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Apenas utilizadores autenticados podem executar esta ação.");
  }

  // 2. Verificar se o chamador é um administrador
  const adminRef = db.collection("users").doc(context.auth.uid);
  const adminDoc = await adminRef.get();

  if (!adminDoc.exists || adminDoc.data().role !== 'admin') {
    throw new functions.https.HttpsError("permission-denied", "Apenas administradores podem forçar a verificação de um utilizador.");
  }

  // 3. Validar o input
  const { email } = data;
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "O 'email' do utilizador-alvo é obrigatório.");
  }

  try {
    // 4. Encontrar o utilizador pelo email
    const userRecord = await admin.auth().getUserByEmail(email);
    const uid = userRecord.uid;

    // 5. Atualizar o utilizador para "email_verified: true"
    await admin.auth().updateUser(uid, {
      emailVerified: true,
    });
    
    console.log(`O utilizador ${email} (UID: ${uid}) foi marcado como verificado pelo administrador ${context.auth.token.email}.`);

    return { status: "success", message: `O utilizador ${email} foi verificado com sucesso.` };

  } catch (error) {
    console.error(`Falha ao forçar a verificação para ${email}:`, error);
    if (error.code === 'auth/user-not-found') {
        throw new functions.https.HttpsError("not-found", `O utilizador com o email ${email} não foi encontrado.`);
    }
    throw new functions.https.HttpsError("internal", "Ocorreu um erro inesperado ao tentar verificar o utilizador.", error.message);
  }
});


// --- CONSTANTES DE CONFIGURAÇÃO ---
const PLATFORM_FEE_RATE = 0.015; // 1.5%
const CASHIER_FEE_RATE = 0.035; // 3.5%

/**
 * Envia uma notificação para um utilizador.
 */
const sendNotification = (userId, title, body, type) => {
  if (!userId || !title || !body) {
    console.warn("Tentativa de envio de notificação com parâmetros em falta.");
    return Promise.resolve();
  }
  return db.collection("users").doc(userId).collection("notifications").add({
    title,
    body,
    date: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
    type,
  });
};

// --- FUNÇÃO: CRIAR PEDIDO DE CÂMBIO COM RETENÇÃO ---
exports.createExchangeRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "É necessário estar autenticado.");
  }

  const { amountKz, targetCurrency, paymentDetails } = data;
  const clientId = context.auth.uid;

  if (!amountKz || typeof amountKz !== 'number' || amountKz <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "O 'amountKz' deve ser um número positivo.");
  }
  if (!targetCurrency || typeof targetCurrency !== 'string') {
    throw new functions.https.HttpsError("invalid-argument", "A 'targetCurrency' é obrigatória.");
  }
  if (!paymentDetails || typeof paymentDetails !== 'string' || paymentDetails.trim() === '') {
    throw new functions.https.HttpsError("invalid-argument", "Os 'paymentDetails' (detalhes de pagamento) são obrigatórios.");
  }

  const clientRef = db.collection("users").doc(clientId);
  const requestRef = db.collection("foreign_withdrawal_requests").doc();

  const platformFee = parseFloat((amountKz * PLATFORM_FEE_RATE).toFixed(2));
  const cashierFee = parseFloat((amountKz * CASHIER_FEE_RATE).toFixed(2));
  const totalAmountToHold = amountKz + platformFee + cashierFee;

  try {
    await db.runTransaction(async (transaction) => {
      const clientDoc = await transaction.get(clientRef);
      if (!clientDoc.exists) {
        throw new functions.https.HttpsError("not-found", "O seu perfil de utilizador não foi encontrado.");
      }

      const clientData = clientDoc.data();
      const currentBalance = clientData.balance || 0;

      if (currentBalance < totalAmountToHold) {
        throw new functions.https.HttpsError("failed-precondition", `Saldo insuficiente. Necessita de ${totalAmountToHold.toFixed(2)} Kz, mas tem apenas ${currentBalance.toFixed(2)} Kz.`);
      }

      transaction.update(clientRef, {
        balance: admin.firestore.FieldValue.increment(-totalAmountToHold)
      });

      transaction.set(requestRef, {
        userId: clientId,
        displayName: clientData.displayName || "Utilizador Anónimo",
        amountKz: amountKz,
        targetCurrency: targetCurrency,
        platformFee: platformFee,
        cashierFee: cashierFee,
        totalAmount: totalAmountToHold,
        paymentDetails: paymentDetails,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const clientTransactionRef = clientRef.collection("transactions").doc();
      transaction.set(clientTransactionRef, {
          amount: totalAmountToHold,
          date: admin.firestore.FieldValue.serverTimestamp(),
          description: `Retenção para pedido de câmbio #${requestRef.id.substring(0, 5)}`,
          type: "hold",
          requestId: requestRef.id,
      });
    });

    return { status: "success", message: "Pedido de câmbio criado com sucesso.", requestId: requestRef.id };

  } catch (error) {
    console.error(`Erro ao criar pedido de câmbio para ${clientId}:`, error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError("internal", "Ocorreu um erro inesperado ao criar o pedido.", error.message);
  }
});


// --- FUNÇÃO: CANCELAR PEDIDO DE CÂMBIO ---
exports.cancelExchangeRequest = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "É necessário estar autenticado.");
    }

    const { requestId } = data;
    const userId = context.auth.uid;

    if (!requestId) {
        throw new functions.https.HttpsError("invalid-argument", "O 'requestId' é obrigatório.");
    }

    const requestRef = db.collection("foreign_withdrawal_requests").doc(requestId);
    const userRef = db.collection("users").doc(userId);

    try {
        await db.runTransaction(async (transaction) => {
            const requestDoc = await transaction.get(requestRef);
            const userDoc = await transaction.get(userRef);

            if (!requestDoc.exists) {
                throw new functions.https.HttpsError("not-found", "O pedido especificado não foi encontrado.");
            }
            if (!userDoc.exists) {
                throw new functions.https.HttpsError("not-found", "O seu perfil de utilizador não foi encontrado.");
            }
            
            const requestData = requestDoc.data();
            const userData = userDoc.data();
            const isAdmin = userData.role === 'admin';

            if (requestData.userId !== userId && !isAdmin) {
                throw new functions.https.HttpsError("permission-denied", "Não tem permissão para cancelar este pedido.");
            }

            if (requestData.status !== "pending") {
                throw new functions.https.HttpsError("failed-precondition", `Apenas pedidos 'pending' podem ser cancelados. Estado atual: ${requestData.status}.`);
            }
            
            const clientToRefundRef = db.collection("users").doc(requestData.userId);
            transaction.update(clientToRefundRef, {
                balance: admin.firestore.FieldValue.increment(requestData.totalAmount)
            });

            transaction.update(requestRef, {
                status: "cancelled",
                cancelledBy: userId,
                cancelledAt: admin.firestore.FieldValue.serverTimestamp()
            });

            const clientTransactionRef = clientToRefundRef.collection("transactions").doc();
            transaction.set(clientTransactionRef, {
                amount: requestData.totalAmount,
                date: admin.firestore.FieldValue.serverTimestamp(),
                description: `Devolução do pedido de câmbio #${requestId.substring(0, 5)}`,
                type: "refund",
                requestId: requestId,
            });
        });

        return { status: "success", message: "Pedido cancelado com sucesso." };

    } catch (error) {
        console.error(`Erro ao cancelar pedido ${requestId}:`, error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError("internal", "Ocorreu um erro ao cancelar o pedido.");
    }
});


// --- FUNÇÃO: GERIR PEDIDOS DE CÂMBIO ---
exports.manageExchangeRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "É necessário estar autenticado.");
  }

  const { action, requestId } = data;
  const userId = context.auth.uid;

  if (!action || !requestId) {
    throw new functions.https.HttpsError("invalid-argument", "Faltam 'action' ou 'requestId'.");
  }

  const requestRef = db.collection("foreign_withdrawal_requests").doc(requestId);

  try {
    await db.runTransaction(async (transaction) => {
      const requestDoc = await transaction.get(requestRef);
      if (!requestDoc.exists) {
        throw new functions.https.HttpsError("not-found", "O pedido de câmbio não foi encontrado.");
      }
      
      const requestData = requestDoc.data();
      const userRef = db.collection("users").doc(userId);
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
          throw new functions.https.HttpsError("not-found", "O seu perfil de utilizador não foi encontrado.");
      }
      const userData = userDoc.data();

      switch (action) {
        case "accept":
          if (userData.role !== 'cashier') {
            throw new functions.https.HttpsError("permission-denied", "Apenas caixas podem aceitar pedidos.");
          }
          if (requestData.status !== "pending") {
            throw new functions.https.HttpsError("failed-precondition", "Este pedido já não está pendente.");
          }

          transaction.update(requestRef, {
            status: "processing",
            processedBy: userId,
            cashierName: userData.displayName || "Caixa Anónimo",
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          
          await sendNotification(requestData.userId, "Pedido Aceite", `O seu pedido de câmbio foi aceite.`, "exchange_accepted");
          break;

        case "confirm_funds_sent":
          if (requestData.processedBy !== userId) {
            throw new functions.https.HttpsError("permission-denied", "Apenas o caixa do pedido pode confirmar o envio.");
          }
          if (requestData.status !== "processing") {
            throw new functions.https.HttpsError("failed-precondition", `O estado do pedido é '${requestData.status}'.`);
          }

          transaction.update(requestRef, {
            status: "funds_sent",
            fundsSentAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await sendNotification(requestData.userId, "Fundos Enviados", "O caixa enviou os fundos. Por favor, confirme o recebimento.", "funds_sent");
          break;

        case "confirm_receipt":
          if (requestData.userId !== userId) {
            throw new functions.https.HttpsError("permission-denied", "Apenas o criador do pedido pode confirmar o recebimento.");
          }
          if (requestData.status !== "funds_sent") {
            throw new functions.https.HttpsError("failed-precondition", `Estado do pedido: '${requestData.status}'.`);
          }

          const cashierId = requestData.processedBy;
          if (!cashierId) {
            throw new functions.https.HttpsError("internal", "ERRO CRÍTICO: Caixa não associado.");
          }

          const cashierRef = db.collection("users").doc(cashierId);

          transaction.update(requestRef, {
            status: "completed",
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          
          transaction.update(cashierRef, {
            balance: admin.firestore.FieldValue.increment(requestData.amountKz)
          });
          
          transaction.update(cashierRef, {
            commissionBalance: admin.firestore.FieldValue.increment(requestData.cashierFee)
          });

          const reimbursementTransactionRef = cashierRef.collection("transactions").doc();
          transaction.set(reimbursementTransactionRef, {
              amount: requestData.amountKz,
              date: admin.firestore.FieldValue.serverTimestamp(),
              description: `Reembolso pelo pedido #${requestId.substring(0, 5)}`,
              type: "revenue",
              source: "exchange_reimbursement",
              requestId: requestId,
          });

          const commissionTransactionRef = cashierRef.collection("transactions").doc();
           transaction.set(commissionTransactionRef, {
              amount: requestData.cashierFee,
              date: admin.firestore.FieldValue.serverTimestamp(),
              description: `Comissão pelo pedido #${requestId.substring(0, 5)}`,
              type: "revenue",
              source: "exchange_commission",
              requestId: requestId,
          });

          await sendNotification(cashierId, "Comissão Recebida", `Recebeu ${requestData.cashierFee.toFixed(2)} Kz de comissão e ${requestData.amountKz.toFixed(2)} Kz de reembolso.`, "commission_paid");
          break;

        default:
          throw new functions.https.HttpsError("invalid-argument", `A ação '${action}' não é reconhecida.`);
      }
    });
    
    return { status: "success", message: `Ação '${action}' executada.` };

  } catch (error) {
    console.error(`Erro ao executar '${action}' no pedido ${requestId}:`, error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError("internal", "Erro inesperado na gestão do pedido.", error.message);
  }
});


// --- FUNÇÃO PARA PROCESSAR PEDIDOS DE LEVANTAMENTO ---
exports.processWithdrawalRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError("permission-denied", "Apenas administradores.");
  }
  const { requestId, action } = data;
  if (!requestId || !action || !['approve', 'reject'].includes(action)) {
    throw new functions.https.HttpsError("invalid-argument", "Faltam 'requestId' e 'action'.");
  }
  const requestRef = db.collection("withdrawal_requests").doc(requestId);
  try {
    const requestDoc = await requestRef.get();
    if (!requestDoc.exists) throw new functions.https.HttpsError("not-found", "Pedido não encontrado.");
    const requestData = requestDoc.data();
    if (requestData.status !== 'pending') throw new functions.https.HttpsError("failed-precondition", `Pedido já processado (estado: ${requestData.status}).`);
    if (action === 'approve') {
      await db.runTransaction(async (transaction) => {
        const userRef = db.collection('users').doc(requestData.userId);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new functions.https.HttpsError("not-found", "Utilizador do pedido não encontrado.");
        const userBalance = userDoc.data().balance || 0;
        const withdrawalAmount = requestData.amount;
        if (userBalance < withdrawalAmount) {
            transaction.update(requestRef, { status: 'rejected', processedAt: admin.firestore.FieldValue.serverTimestamp(), reason: 'Saldo insuficiente.' });
            await sendNotification(requestData.userId, "Levantamento Rejeitado", `O seu levantamento de ${withdrawalAmount.toFixed(2)} Kz foi rejeitado por saldo insuficiente.`,"withdrawal_rejected");
            return;
        }
        transaction.update(userRef, { balance: admin.firestore.FieldValue.increment(-withdrawalAmount) });
        const userTransactionRef = userRef.collection('transactions').doc();
        transaction.set(userTransactionRef, { amount: withdrawalAmount, date: admin.firestore.FieldValue.serverTimestamp(), description: `Levantamento Aprovado: ${requestData.beneficiaryName}`, type: 'expense'});
        transaction.update(requestRef, { status: 'completed', processedAt: admin.firestore.FieldValue.serverTimestamp() });
      });
      await sendNotification(requestData.userId, "Levantamento Aprovado", `O seu levantamento de ${requestData.amount.toFixed(2)} Kz foi aprovado.`, "withdrawal_approved");
    } else {
      await requestRef.update({ status: 'rejected', processedAt: admin.firestore.FieldValue.serverTimestamp() });
      await sendNotification(requestData.userId, "Levantamento Rejeitado", `O seu levantamento de ${requestData.amount.toFixed(2)} Kz foi rejeitado.`, "withdrawal_rejected");
    }
    return { success: true, message: `Pedido ${requestId} marcado como '${action}'.` };
  } catch (error) {
    console.error("Erro ao processar levantamento:", error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError("internal", "Ocorreu um erro inesperado.", error.message);
  }
});

// --- FUNÇÃO PARA ANÁLISE DE CRÉDITO ---
exports.requestCreditAnalysis = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Apenas utilizadores autenticados.");
  }

  const { creditType } = data;
  if (!creditType || !['personal', 'business'].includes(creditType)) {
    throw new functions.https.HttpsError("invalid-argument", "O tipo de crédito é obrigatório.");
  }

  const userId = context.auth.uid;
  const userRef = db.collection("users").doc(userId);

  const PERSONAL_CREDIT_FEE = 500;
  const BUSINESS_CREDIT_FEE = 1000;
  const analysisFee = creditType === 'personal' ? PERSONAL_CREDIT_FEE : BUSINESS_CREDIT_FEE;
  const creditDescription = creditType === 'personal' ? 'Crédito Pessoal' : 'Crédito Empresarial';

  try {
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Utilizador não encontrado.");
      }

      const userData = userDoc.data();
      const userBalance = userData.balance || 0;

      if (userBalance < analysisFee) {
        throw new functions.https.HttpsError("failed-precondition", `Saldo insuficiente para a taxa de ${analysisFee} Kz.`);
      }

      transaction.update(userRef, { balance: admin.firestore.FieldValue.increment(-analysisFee) });

      const creditRequestRef = db.collection("credit_requests").doc();
      transaction.set(creditRequestRef, {
        userId: userId,
        userName: userData.displayName || 'Desconhecido',
        userEmail: userData.email,
        creditType: creditType,
        status: "pending_analysis",
        requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        analysisFee: analysisFee,
      });

      const feeTransactionRef = userRef.collection("transactions").doc();
      transaction.set(feeTransactionRef, {
        description: `Taxa de Análise para ${creditDescription}`,
        amount: analysisFee,
        date: admin.firestore.FieldValue.serverTimestamp(),
        type: "expense",
        category: "credit_analysis_fee",
      });
    });

    await sendNotification(userId, "Pedido de Crédito Recebido", `O seu pedido de ${creditDescription} foi submetido. A taxa de ${analysisFee} Kz foi debitada.`, "credit_request");

    return { status: "success", message: `Pedido de ${creditDescription} submetido.` };

  } catch (error) {
    console.error(`Erro ao solicitar crédito para ${userId}:`, error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError("internal", "Ocorreu um erro inesperado.");
  }
});
