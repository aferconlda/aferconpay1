const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function to handle a P2P transfer between two users.
 *
 * This function is callable from a client application (e.g., Flutter).
 * It expects 'recipientId', 'amount', and 'description' in the data payload.
 * The 'senderId' is derived from the authenticated user context.
 *
 * It performs the following actions in a single atomic Firestore transaction:
 * 1. Verifies that the sender and recipient users exist.
 * 2. Checks if the sender has sufficient balance.
 * 3. Atomically updates the balances of both the sender and the recipient.
 * 4. Creates a transaction record for the sender (type 'transfer_out').
 * 5. Creates a transaction record for the recipient (type 'transfer_in').
 *
 * After the transaction, it sends notifications to both users.
 *
 * @throws {functions.https.HttpsError} Throws errors with specific error codes
 * for different failure scenarios, such as 'unauthenticated', 'not-found',
 * 'invalid-argument', or 'failed-precondition'.
 */
exports.p2pTransfer = functions.https.onCall(async (data, context) => {
  // 1. Authentication and Validation
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const senderId = context.auth.uid;
  const { recipientId, amount, description } = data;

  // Basic validation for input data
  if (!recipientId || typeof recipientId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The 'recipientId' must be a non-empty string.",
    );
  }
  if (!amount || typeof amount !== "number" || amount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The 'amount' must be a positive number.",
    );
  }
  if (senderId === recipientId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Sender and recipient cannot be the same person.",
    );
  }

  // 2. References to the user documents in Firestore
  const senderRef = db.collection("users").doc(senderId);
  const recipientRef = db.collection("users").doc(recipientId);

  try {
    // 3. Execute the core logic within a Firestore transaction
    await db.runTransaction(async (transaction) => {
      const senderDoc = await transaction.get(senderRef);
      const recipientDoc = await transaction.get(recipientRef);

      if (!senderDoc.exists || !recipientDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Sender or recipient user not found.",
        );
      }

      const senderData = senderDoc.data();
      const recipientData = recipientDoc.data();

      // Check for sufficient funds
      const senderBalance = senderData.balance.AOA || 0;
      if (senderBalance < amount) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Insufficient funds for this transfer.",
        );
      }

      // Calculate new balances
      const newSenderBalance = senderBalance - amount;
      const newRecipientBalance = (recipientData.balance.AOA || 0) + amount;

      // Update balances
      transaction.update(senderRef, { "balance.AOA": newSenderBalance });
      transaction.update(recipientRef, { "balance.AOA": newRecipientBalance });

      // Create transaction records for both users
      const now = admin.firestore.Timestamp.now();
      const commonTransactionDetails = {
        date: now,
        status: "completed",
        currency: "AOA",
        senderId: senderId,
        recipientId: recipientId,
        amount: Math.abs(amount), // Store positive amount for clarity
      };

      const senderTransactionRef = senderRef.collection("transactions").doc();
      transaction.set(senderTransactionRef, {
        ...commonTransactionDetails,
        id: senderTransactionRef.id,
        userId: senderId,
        type: "transfer_out",
        description: description || `Transfer to ${recipientData.displayName || "user"}`,
        amount: -Math.abs(amount), // Negative for sender
      });

      const recipientTransactionRef = recipientRef.collection("transactions").doc();
      transaction.set(recipientTransactionRef, {
        ...commonTransactionDetails,
        id: recipientTransactionRef.id,
        userId: recipientId,
        type: "transfer_in",
        description: `Received from ${senderData.displayName || "user"}`,
      });
    });

    // 4. Send Notifications (after the transaction is successfully committed)
    const senderDoc = await senderRef.get();
    const recipientDoc = await recipientRef.get();
    const senderName = senderDoc.data().displayName || "A user";
    const recipientName = recipientDoc.data().displayName || "A user";

    const notificationPayloadSender = {
      userId: senderId,
      title: "Transfer Sent",
      body: `You sent ${amount.toFixed(2)} AOA to ${recipientName}.`,
      isRead: false,
      createdAt: admin.firestore.Timestamp.now(),
    };
    const notificationPayloadRecipient = {
      userId: recipientId,
      title: "Transfer Received",
      body: `You received ${amount.toFixed(2)} AOA from ${senderName}.`,
      isRead: false,
      createdAt: admin.firestore.Timestamp.now(),
    };

    // Use a batch write for efficiency
    const batch = db.batch();
    batch.set(db.collection("users").doc(senderId).collection("notifications").doc(), notificationPayloadSender);
    batch.set(db.collection("users").doc(recipientId).collection("notifications").doc(), notificationPayloadRecipient);
    await batch.commit();


    return { status: "success", message: "Transfer completed successfully." };
  } catch (error) {
    console.error("p2pTransfer failed:", error);
    // Re-throw HttpsError to be caught by the client
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    // For other errors, throw a generic internal error
    throw new functions.https.HttpsError(
      "internal",
      "An unexpected error occurred during the transfer.",
      error.message,
    );
  }
});
