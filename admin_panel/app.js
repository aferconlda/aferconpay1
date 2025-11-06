
// !!! IMPORTANTE !!!
// Substitua os valores abaixo pelos dados de configuração do seu projeto Firebase.
// Pode encontrar estes dados na consola do Firebase em: Definições do projeto > Suas aplicações > Configuração do SDK.
const firebaseConfig = {
    apiKey: "SUA_API_KEY",
    authDomain: "SEU_AUTH_DOMAIN",
    projectId: "SEU_PROJECT_ID",
    storageBucket: "SEU_STORAGE_BUCKET",
    messagingSenderId: "SEU_MESSAGING_SENDER_ID",
    appId: "SEU_APP_ID"
};

// Inicializar a aplicação Firebase
const app = firebase.initializeApp(firebaseConfig);
const auth = firebase.getAuth(app);
const firestore = firebase.getFirestore(app);
// A região aqui deve corresponder à região das suas funções HTTPS Callable
const functions = firebase.getFunctions(app, 'us-central1'); 

const withdrawalRequestsList = document.getElementById('withdrawal-requests-list');
const creditRequestsList = document.getElementById('credit-requests-list');
const transferRequestsList = document.getElementById('transfer-requests-list');


async function handleRequest(id, type, action) {
    const card = document.getElementById(`${type}-${id}`);
    const approveBtn = card.querySelector('.approve-btn');
    const rejectBtn = card.querySelector('.reject-btn');

    approveBtn.disabled = true;
    rejectBtn.disabled = true;
    approveBtn.textContent = 'A processar...';
    rejectBtn.textContent = 'A processar...';

    try {
        let processFunction;
        // Mapeia o tipo de pedido para a Cloud Function correspondente
        switch (type) {
            case 'withdrawal':
                // Nota: Verifique se o nome da função e a região estão corretos
                processFunction = firebase.httpsCallable(functions, 'processWithdrawalRequest');
                break;
            case 'credit':
                // AQUI ESTÁ A MUDANÇA: Aponta para a nova função de crédito
                processFunction = firebase.httpsCallable(functions, 'processCreditRequest');
                break;
            case 'transfer': // A lógica de transferência ainda não é uma função callable
                throw new Error(`A lógica para '${type}' ainda não foi implementada como uma ação de admin.`);
            default:
                throw new Error('Tipo de pedido desconhecido.');
        }

        // Chama a Cloud Function com os dados necessários
        const result = await processFunction({ requestId: id, action: action });
        
        console.log('Resultado da Cloud Function:', result.data.message);
        
        // Animação para remover o card da lista
        card.style.opacity = '0';
        card.style.transform = 'scale(0.9)';
        setTimeout(() => card.remove(), 300); 

    } catch (error) {
        console.error("Erro ao processar o pedido:", error);
        alert(`Erro: ${error.message}`);
        // Reativa os botões em caso de erro
        approveBtn.disabled = false;
        rejectBtn.disabled = false;
        approveBtn.textContent = 'Aprovar';
        rejectBtn.textContent = 'Rejeitar';
    }
}


const loginSection = document.getElementById('login-section');
const dashboardSection = document.getElementById('dashboard-section');
const loginButton = document.getElementById('login-button');
const logoutButton = document.getElementById('logout-button');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const errorMessage = document.getElementById('error-message');
const adminEmailSpan = document.getElementById('admin-email');

loginButton.addEventListener('click', () => {
    const email = emailInput.value;
    const password = passwordInput.value;
    if (!email || !password) {
        showError("Por favor, preencha o email e a senha.");
        return;
    }
    firebase.signInWithEmailAndPassword(auth, email, password)
        .then((userCredential) => {
            const user = userCredential.user;
            user.getIdTokenResult(true).then((idTokenResult) => {
                if (idTokenResult.claims.admin) {
                    showDashboard(user.email);
                } else {
                    firebase.signOut(auth);
                    showError("Acesso negado. Apenas para administradores.");
                }
            });
        })
        .catch(() => {
            showError("Email ou senha inválidos.");
        });
});

logoutButton.addEventListener('click', () => {
    firebase.signOut(auth).then(showLogin);
});

function showDashboard(email) {
    loginSection.classList.add('hidden');
    dashboardSection.classList.remove('hidden');
    adminEmailSpan.textContent = email;
    errorMessage.classList.add('hidden');
    loadAllRequests();
}

function showLogin() {
    loginSection.classList.remove('hidden');
    dashboardSection.classList.add('hidden');
    emailInput.value = '';
    passwordInput.value = '';
}

function showError(message) {
    errorMessage.textContent = message;
    errorMessage.classList.remove('hidden');
}

function loadAllRequests() {
    loadWithdrawalRequests();
    loadCreditRequests();
    loadTransferRequests();
}

function loadWithdrawalRequests() {
    const q = firestore.query(firestore.collection(firestore, 'withdrawal_requests'), firestore.where('status', '==', 'pending'));
    firestore.onSnapshot(q, snapshot => {
        withdrawalRequestsList.innerHTML = '<h3>Carregando...</h3>';
        if (snapshot.empty) {
            withdrawalRequestsList.innerHTML = '<p>Nenhum pedido de levantamento pendente.</p>';
            return;
        }
        withdrawalRequestsList.innerHTML = '';
        snapshot.forEach(doc => {
            const request = doc.data();
            const element = createRequestElement(doc.id, request, 'withdrawal');
            withdrawalRequestsList.appendChild(element);
        });
    });
}

function loadCreditRequests() {
    const q = firestore.query(firestore.collection(firestore, 'credit_applications'), firestore.where('status', '==', 'pending'));
    firestore.onSnapshot(q, snapshot => {
        creditRequestsList.innerHTML = '<h3>Carregando...</h3>';
        if (snapshot.empty) {
            creditRequestsList.innerHTML = '<p>Nenhum pedido de crédito pendente.</p>';
            return;
        }
        creditRequestsList.innerHTML = '';
        snapshot.forEach(doc => {
            const request = doc.data();
            const element = createRequestElement(doc.id, request, 'credit');
            creditRequestsList.appendChild(element);
        });
    });
}

function loadTransferRequests() {
    const q = firestore.query(firestore.collection(firestore, 'transfer_requests'), firestore.where('status', '==', 'pending'));
    firestore.onSnapshot(q, snapshot => {
        transferRequestsList.innerHTML = '<h3>Carregando...</h3>';
        if (snapshot.empty) {
            transferRequestsList.innerHTML = '<p>Nenhum pedido de transferência pendente.</p>';
            return;
        }
        transferRequestsList.innerHTML = '';
        snapshot.forEach(doc => {
            const request = doc.data();
            const element = createRequestElement(doc.id, request, 'transfer');
            transferRequestsList.appendChild(element);
        });
    });
}

function createRequestElement(id, data, type) {
    const card = document.createElement('div');
    card.className = 'request-card';
    card.id = `${type}-${id}`;

    let details = '';
    const amount = formatCurrency(data.amount);
    const date = data.createdAt ? data.createdAt.toDate().toLocaleString('pt-PT') : 'N/A';

    switch (type) {
        case 'withdrawal':
            details = `
                <p><strong>Utilizador:</strong> ${data.userDisplayName || data.userEmail}</p>
                <p><strong>Valor:</strong> ${amount}</p>
                <p><strong>IBAN:</strong> ${data.iban}</p>
                <p><strong>Beneficiário:</strong> ${data.beneficiaryName}</p>
            `;
            break;
        case 'credit':
            details = `
                <p><strong>Utilizador:</strong> ${data.userDisplayName || data.userEmail}</p>
                <p><strong>Valor do Crédito:</strong> ${amount}</p>
                <p><strong>Tipo:</strong> ${data.creditType}</p>
                <p><strong>Salário:</strong> ${formatCurrency(data.monthlyIncome)}</p>
            `;
            break;
        case 'transfer':
            details = `
                <p><strong>De:</strong> ${data.senderName || data.senderEmail}</p>
                <p><strong>Para ID:</strong> ${data.recipientId}</p>
                <p><strong>Valor:</strong> ${amount}</p>
                <p><strong>Descrição:</strong> ${data.description}</p>
            `;
            break;
    }

    card.innerHTML = `
        <div class="card-details">
            ${details}
            <p><strong>Data:</strong> ${date}</p>
        </div>
        <div class="card-actions">
            <button class="approve-btn">Aprovar</button>
            <button class="reject-btn">Rejeitar</button>
        </div>
    `;

    card.querySelector('.approve-btn').addEventListener('click', () => handleRequest(id, type, 'approve'));
    card.querySelector('.reject-btn').addEventListener('click', () => handleRequest(id, type, 'reject'));

    return card;
}

function formatCurrency(value) {
    if (typeof value !== 'number') return 'N/A';
    return new Intl.NumberFormat('pt-AO', { style: 'currency', currency: 'AOA' }).format(value);
}

// Monitoriza o estado da autenticação
firebase.onAuthStateChanged(auth, (user) => {
    if (user) {
        user.getIdTokenResult(true).then((idTokenResult) => {
            // Garante que apenas administradores podem ver o painel
            if (idTokenResult.claims.admin) {
                showDashboard(user.email);
            } else {
                // Se não for admin, força o logout
                firebase.signOut(auth);
                showLogin();
                showError("Acesso negado. Apenas para administradores.");
            }
        });
    } else {
        showLogin();
    }
});
