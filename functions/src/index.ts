
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {AuthData} from "firebase-functions/v2/tasks";

admin.initializeApp();
const db = admin.firestore();

// ===================================================================
// == FUNÇÕES AUXILIARES
// ===================================================================

const ensureIsAdmin = (auth: AuthData | undefined) => {
  if (!auth || !auth.token.admin) {
    throw new HttpsError("permission-denied", "Apenas administradores podem executar esta operação.");
  }
};

const sendNotification = (userId: string, title: string, body: string, type: string) => {
    if (!userId || !title || !body || !type) {
        console.warn("Tentativa de envio de notificação com parâmetros em falta.");
        return Promise.resolve(); // Não quebrar a cadeia de execução
    }
    return db.collection("users").doc(userId).collection("notifications").add({
        title,
        body,
        date: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        type,
    });
};

// ===================================================================
// == FUNÇÕES DE GESTÃO DE UTILIZADORES E AUTENTICAÇÃO
// ===================================================================

export const registerUser = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Apenas utilizadores autenticados podem criar registos.");
    }
    const { displayName, nif } = request.data;
    const uid = request.auth.uid;
    const email = request.auth.token.email;
    if (!displayName || !nif) {
        throw new HttpsError("invalid-argument", "O 'displayName' (nome) e 'nif' são obrigatórios.");
    }
    const userRef = db.collection("users").doc(uid);
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
        }, { merge: true });
        console.log(`Documento do utilizador ${uid} criado/atualizado com sucesso para ${email}.`);
        return { status: "success", message: "Documento do utilizador processado com sucesso.", userId: uid };
    } catch (error: any) {
        console.error(`Erro ao processar documento para o utilizador ${uid}:`, error);
        throw new HttpsError("internal", "Não foi possível guardar os dados do utilizador na base de dados.", error.message);
    }
});

export const forceVerifyUser = onCall(async (request) => {
    ensureIsAdmin(request.auth);
    const { email } = request.data;
    if (!email) {
        throw new HttpsError("invalid-argument", "O 'email' do utilizador-alvo é obrigatório.");
    }
    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        await admin.auth().updateUser(userRecord.uid, { emailVerified: true });
        console.log(`O utilizador ${email} (UID: ${userRecord.uid}) foi marcado como verificado pelo administrador ${request.auth?.token.email}.`);
        return { status: "success", message: `O utilizador ${email} foi verificado com sucesso.` };
    } catch (error: any) {
        console.error(`Falha ao forçar a verificação para ${email}:`, error);
        if (error.code === 'auth/user-not-found') {
            throw new HttpsError("not-found", `O utilizador com o email ${email} não foi encontrado.`);
        }
        throw new HttpsError("internal", "Ocorreu um erro inesperado ao tentar verificar o utilizador.", error.message);
    }
});


// ===================================================================
// == FUNÇÕES DE TRANSAÇÕES (P2P, QR Code)
// ===================================================================

const executeTransfer = async (senderId: string, recipientId: string, amount: number, description: string, type: 'p2p' | 'qr') => {
    const senderRef = db.collection("users").doc(senderId);
    const recipientRef = db.collection("users").doc(recipientId);

    await db.runTransaction(async (transaction) => {
        const senderDoc = await transaction.get(senderRef);
        const recipientDoc = await transaction.get(recipientRef);

        if (!senderDoc.exists || !recipientDoc.exists) {
            throw new HttpsError("not-found", "O remetente ou o destinatário não foi encontrado.");
        }
        const senderData = senderDoc.data()!;
        if (senderData.balance < amount) {
            throw new HttpsError("failed-precondition", `Saldo insuficiente.`);
        }
        
        transaction.update(senderRef, { balance: admin.firestore.FieldValue.increment(-amount) });
        transaction.update(recipientRef, { balance: admin.firestore.FieldValue.increment(amount) });
        
        const senderName = senderData.displayName || "Utilizador Anónimo";
        const recipientName = recipientDoc.data()!.displayName || "Utilizador Anónimo";

        const senderTransactionRef = senderRef.collection("transactions").doc();
        transaction.set(senderTransactionRef, {
            amount, date: admin.firestore.FieldValue.serverTimestamp(),
            description: description || `Transferência para ${recipientName}`,
            type: type === 'p2p' ? "p2p_expense" : "qr_expense",
            recipientId, recipientName,
        });

        const recipientTransactionRef = recipientRef.collection("transactions").doc();
        transaction.set(recipientTransactionRef, {
            amount, date: admin.firestore.FieldValue.serverTimestamp(),
            description: `Recebido de ${senderName}`,
            type: type === 'p2p' ? "p2p_revenue" : "qr_revenue",
            senderId, senderName,
        });
    });
    
    try {
        const senderName = (await senderRef.get()).data()?.displayName || "Utilizador Anónimo";
        const recipientName = (await recipientRef.get()).data()?.displayName || "Utilizador Anónimo";
        await sendNotification(recipientId, "Transferência Recebida", `${senderName} enviou-lhe ${amount.toFixed(2)} Kz.`, "transfer_in");
        await sendNotification(senderId, "Transferência Enviada", `Enviou ${amount.toFixed(2)} Kz para ${recipientName}.`, "transfer_out");
    } catch (notificationError) {
        console.error("Transação financeira bem sucedida, mas o envio de notificações falhou:", notificationError);
    }
};

export const performP2PTransfer = onCall({ region: "europe-west1" }, async (request) => {
    if (!request.auth) { throw new HttpsError("unauthenticated", "É necessário estar autenticado."); }
    const senderId = request.auth.uid;
    const { recipientId, amount, description } = request.data;
    if (!recipientId || typeof recipientId !== "string" || !(amount > 0)) {
        throw new HttpsError("invalid-argument", "Dados inválidos: 'recipientId' e 'amount' são obrigatórios.");
    }
    if (senderId === recipientId) { throw new HttpsError("invalid-argument", "Não pode enviar dinheiro para si mesmo."); }

    try {
        await executeTransfer(senderId, recipientId, amount, description, 'p2p');
        return { status: "success", message: "Transferência realizada com sucesso!" };
    } catch (error: any) {
        console.error(`Erro na transferência P2P de ${senderId} para ${recipientId}:`, error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", "Ocorreu um erro inesperado.", error.message);
    }
});

export const processQrTransaction = onCall({ region: "europe-west1" }, async (request) => {
    if (!request.auth) { throw new HttpsError("unauthenticated", "É necessário estar autenticado."); }
    const senderId = request.auth.uid;
    const { recipientId, amount } = request.data;
    if (!recipientId || typeof recipientId !== "string" || !(amount > 0)) {
        throw new HttpsError("invalid-argument", "Dados inválidos: 'recipientId' e 'amount' são obrigatórios.");
    }
    if (senderId === recipientId) { throw new HttpsError("invalid-argument", "Não pode enviar dinheiro para si mesmo."); }

    try {
        await executeTransfer(senderId, recipientId, amount, `Pagamento por QR Code`, 'qr');
        return { status: "success", message: "Pagamento QR realizado com sucesso!" };
    } catch (error: any) {
        console.error(`Erro no pagamento QR de ${senderId} para ${recipientId}:`, error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", "Ocorreu um erro inesperado.", error.message);
    }
});

// ===================================================================
// == FUNÇÕES DE GESTÃO DE PEDIDOS E CAIXA (CÓDIGO ORIGINAL)
// ===================================================================

export const processWithdrawalRequest = onCall(async (request) => {
  ensureIsAdmin(request.auth);
  const { requestId, action } = request.data;
  if (!requestId || !action || !['approve', 'reject'].includes(action)) {
    throw new HttpsError("invalid-argument", "Faltam os parâmetros 'requestId' e 'action' ('approve' ou 'reject').");
  }
  const requestRef = db.collection("withdrawal_requests").doc(requestId);
  try {
    const requestDoc = await requestRef.get();
    if (!requestDoc.exists) { throw new HttpsError("not-found", "Pedido não encontrado."); }
    const requestData = requestDoc.data()!;
    if (requestData.status !== 'pending') {
      throw new HttpsError("failed-precondition",`Este pedido já foi processado (estado: ${requestData.status}).`);
    }
    if (action === 'approve') {
      await db.runTransaction(async (transaction) => {
        const userRef = db.collection('users').doc(requestData.userId);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) { throw new HttpsError("not-found", "Utilizador associado ao pedido não foi encontrado."); }
        const userBalance = userDoc.data()!.balance || 0;
        const withdrawalAmount = requestData.amount;
        if (userBalance < withdrawalAmount) {
            transaction.update(requestRef, { status: 'rejected', processedAt: admin.firestore.FieldValue.serverTimestamp(), reason: 'Saldo insuficiente no momento da aprovação.' });
            await sendNotification(requestData.userId,"Levantamento Rejeitado",`O seu pedido de levantamento de ${withdrawalAmount.toFixed(2)} Kz foi rejeitado porque o seu saldo era insuficiente. `,"withdrawal_rejected");
            return;
        }
        transaction.update(userRef, { balance: admin.firestore.FieldValue.increment(-withdrawalAmount) });
        const userTransactionRef = userRef.collection('transactions').doc();
        transaction.set(userTransactionRef, {
            amount: withdrawalAmount, date: admin.firestore.FieldValue.serverTimestamp(),
            description: `Levantamento Aprovado: ${requestData.beneficiaryName}`, type: 'expense'
        });
        transaction.update(requestRef, { status: 'completed', processedAt: admin.firestore.FieldValue.serverTimestamp() });
      });
      await sendNotification(requestData.userId, "Levantamento Aprovado", `O seu pedido de levantamento de ${requestData.amount.toFixed(2)} Kz foi aprovado e processado.`, "withdrawal_approved");
    } else { 
      await requestRef.update({ status: 'rejected', processedAt: admin.firestore.FieldValue.serverTimestamp() });
      await sendNotification(requestData.userId, "Levantamento Rejeitado",`O seu pedido de levantamento de ${requestData.amount.toFixed(2)} Kz foi rejeitado pelo administrador.`,"withdrawal_rejected");
    }
    return { success: true, message: `Pedido ${requestId} foi marcado como '${action}'.` };
  } catch (error: any) {
    console.error("Erro ao processar pedido de levantamento:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Ocorreu um erro inesperado.", error.message);
  }
});

export const validateReferrer = onCall(async (request) => {
  const referrerId = request.data.referrerId;
  if (!referrerId || typeof referrerId !== 'string') {
    throw new HttpsError('invalid-argument','O ID de referência (referrerId) é obrigatório e deve ser uma string.');
  }
  try {
    const userDoc = await db.collection('users').doc(referrerId).get();
    return { isValid: userDoc.exists };
  } catch (error: any) {
    console.error("Erro ao validar referrerId:", error);
    throw new HttpsError('internal','Ocorreu um erro ao verificar o código de convite. Tente novamente.');
  }
});

export const processCashDeposit = onCall(async (request) => {
  if (!request.auth) { throw new HttpsError("unauthenticated","A função só pode ser chamada por um utilizador autenticado."); }
  const { clientId, amount, cashierId } = request.data;
  if (request.auth.uid !== cashierId) {
    throw new HttpsError("permission-denied","Não tem permissão para executar esta operação em nome de outro caixa.");
  }
  if (!clientId || typeof clientId !== "string" || !(amount > 0)) {
    throw new HttpsError("invalid-argument","Dados inválidos: 'clientId' (string) e 'amount' (número positivo) são obrigatórios.");
  }
  const cashierRef = db.collection("users").doc(cashierId);
  const clientRef = db.collection("users").doc(clientId);
  try {
    await db.runTransaction(async (transaction) => {
      const cashierDoc = await transaction.get(cashierRef);
      const clientDoc = await transaction.get(clientRef);
      if (!cashierDoc.exists || !clientDoc.exists) { throw new HttpsError("not-found","O cliente ou o caixa não foi encontrado."); }
      const cashierData = cashierDoc.data()!;
      if (cashierData.role !== "cashier") { throw new HttpsError("permission-denied","Esta operação só pode ser realizada por um caixa."); }
      const currentFloat = cashierData.floatBalance || 0;
      if (currentFloat < amount) { throw new HttpsError("failed-precondition",`O seu float (${currentFloat} Kz) é insuficiente.`); }
      
      transaction.update(clientRef, { balance: admin.firestore.FieldValue.increment(amount) });
      transaction.update(cashierRef, { floatBalance: admin.firestore.FieldValue.increment(-amount) });
      
      const clientTransactionRef = clientRef.collection("transactions").doc();
      transaction.set(clientTransactionRef, {
        description: `Depósito em numerário via caixa ${cashierData.displayName || "Desconhecido"}`,
        amount: amount, date: admin.firestore.FieldValue.serverTimestamp(),
        type: "revenue", source: "cash_deposit",
      });
      const cashierTransactionRef = cashierRef.collection("transactions").doc();
      transaction.set(cashierTransactionRef, {
        description: `Entrega de numerário ao cliente ${clientDoc.data()!.displayName || "Desconhecido"}`,
        amount: amount, date: admin.firestore.FieldValue.serverTimestamp(),
        type: "expense", target: "client_deposit",
      });
    });
    console.log(`Depósito de ${amount} Kz processado com sucesso pelo caixa ${cashierId} para o cliente ${clientId}.`);
    return { status: "success", message: "Depósito processado com sucesso!" };
  } catch (error: any) {
    console.error(`Erro ao processar depósito do caixa ${cashierId} para o cliente ${clientId}:`, error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Ocorreu um erro inesperado no servidor.");
  }
});

export const addFloatFromBalance = onCall(async (request) => {
  if (!request.auth) { throw new HttpsError("unauthenticated", "A função só pode ser chamada por um utilizador autenticado."); }
  const amount = request.data.amount;
  if (!(typeof amount === 'number' && amount > 0)) {
    throw new HttpsError("invalid-argument","O 'amount' é obrigatório e deve ser um número positivo.");
  }
  const cashierId = request.auth.uid;
  const cashierRef = db.collection("users").doc(cashierId);
  try {
    await db.runTransaction(async (transaction) => {
      const cashierDoc = await transaction.get(cashierRef);
      if (!cashierDoc.exists) { throw new HttpsError("not-found","O utilizador caixa não foi encontrado."); }
      const cashierData = cashierDoc.data()!;
      if (cashierData.role !== "cashier") { throw new HttpsError("permission-denied","Apenas caixas podem carregar o saldo float."); }
      const currentBalance = cashierData.balance || 0;
      if (currentBalance < amount) {
        throw new HttpsError("failed-precondition",`O seu saldo principal (${currentBalance.toFixed(2)} Kz) é insuficiente.`);
      }
      transaction.update(cashierRef, {
        balance: admin.firestore.FieldValue.increment(-amount),
        floatBalance: admin.firestore.FieldValue.increment(amount),
      });
      const transactionRef = cashierRef.collection("transactions").doc();
      transaction.set(transactionRef, {
        description: `Carregamento de Saldo Float`, amount: amount,
        date: admin.firestore.FieldValue.serverTimestamp(), type: "internal_transfer",
        from: "main_balance", to: "float_balance",
      });
    });
    console.log(`Caixa ${cashierId} transferiu ${amount} do saldo principal para o saldo float.`);
    return { status: "success", message: "Saldo float carregado com sucesso!" };
  } catch (error: any) {
    console.error(`Erro ao carregar saldo float para o caixa ${cashierId}:`, error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Ocorreu um erro inesperado no servidor.");
  }
});

export const manageExchangeRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "É necessário estar autenticado para realizar esta operação.");
  }

  const { action, requestId } = request.data;
  const userId = request.auth.uid;

  if (!action || !requestId) {
    throw new HttpsError("invalid-argument", "A função foi chamada com argumentos em falta ('action' ou 'requestId').");
  }

  const requestRef = db.collection("foreign_withdrawal_requests").doc(requestId);

  return db.runTransaction(async (transaction) => {
    const requestDoc = await transaction.get(requestRef);

    if (!requestDoc.exists) {
      throw new HttpsError("not-found", "O pedido de câmbio especificado não foi encontrado.");
    }

    const requestData = requestDoc.data()!;
    const cashierRef = db.collection("users").doc(userId);

    switch (action) {
      case "accept":
        const cashierDoc = await transaction.get(cashierRef);
        if (!cashierDoc.exists || cashierDoc.data()!.role !== 'cashier') {
            throw new HttpsError("permission-denied", "Apenas caixas podem aceitar pedidos.");
        }
        if (requestData.status !== "pending") {
          throw new HttpsError("failed-precondition", "Este pedido já foi aceite por outro caixa.");
        }
        transaction.update(requestRef, {
          status: "processing",
          processedBy: userId,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { status: "success", message: "Pedido aceite! Pode agora processar o levantamento." };

      case "confirm_receipt":
        if (requestData.userId !== userId) {
          throw new HttpsError("permission-denied", "Apenas o criador do pedido pode confirmar o recebimento.");
        }
        if (requestData.status !== "processing") {
          throw new HttpsError("failed-precondition", `Não pode confirmar o recebimento de um pedido com o estado '${requestData.status}'.`);
        }
        transaction.update(requestRef, {
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const cashierId = requestData.processedBy;
        if (!cashierId) {
            console.log(`Pedido ${requestId} concluído sem um caixa definido. Nenhuma comissão será paga.`);
            return { status: "success", message: "Pedido concluído." };
        }
        const serviceFee = requestData.serviceFee;
        const commissionRate = 0.50; // 50%
        const commissionAmount = parseFloat((serviceFee * commissionRate).toFixed(2));

        if (commissionAmount > 0) {
          const processedByCashierRef = db.collection("users").doc(cashierId);
          const commissionRef = processedByCashierRef.collection("commission_transactions").doc();
          transaction.update(processedByCashierRef, {
            commissionBalance: admin.firestore.FieldValue.increment(commissionAmount),
          });
          transaction.set(commissionRef, {
            amount: commissionAmount,
            date: admin.firestore.FieldValue.serverTimestamp(),
            originalRequestId: requestId,
            details: `Comissão pela troca de ${requestData.amountKz} Kz para ${requestData.targetCurrency}`
          });
        }
        console.log(`Comissão de ${commissionAmount} paga ao caixa ${cashierId} pelo pedido ${requestId}.`);
        return { status: "success", message: "Recebimento confirmado e comissão processada." };

      default:
        throw new HttpsError("invalid-argument", `A ação '${action}' não é reconhecida.`);
    }
  });
});
