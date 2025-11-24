// Configuration
const API_URL = window.location.hostname === 'localhost'
    ? 'http://localhost:8000'
    : 'https://demo-api.local';

// DOM elements
const messageForm = document.getElementById('messageForm');
const messageInput = document.getElementById('messageInput');
const messagesList = document.getElementById('messagesList');
const refreshBtn = document.getElementById('refreshBtn');
const apiStatus = document.getElementById('apiStatus');

// Application state
let isLoading = false;

// Check API status
async function checkApiStatus() {
    try {
        const response = await fetch(`${API_URL}/`);
        const data = await response.json();

        apiStatus.classList.add('connected');
        apiStatus.querySelector('span').textContent = `✅ Connected to API (${data.hostname})`;
        return true;
    } catch (error) {
        apiStatus.classList.add('error');
        apiStatus.querySelector('span').textContent = '❌ Cannot connect to API';
        return false;
    }
}

// Load messages
async function loadMessages() {
    if (isLoading) return;

    isLoading = true;
    messagesList.innerHTML = '<div class="loading">Loading messages...</div>';

    try {
        const response = await fetch(`${API_URL}/api/messages`);

        if (!response.ok) {
            throw new Error('Failed to fetch messages');
        }

        const data = await response.json();
        displayMessages(data.messages);
    } catch (error) {
        console.error('Error loading messages:', error);
        messagesList.innerHTML = `
            <div class="empty-state">
                ❌ Error loading messages<br>
                <small>${error.message}</small>
            </div>
        `;
    } finally {
        isLoading = false;
    }
}

// Display messages
function displayMessages(messages) {
    if (messages.length === 0) {
        messagesList.innerHTML = `
            <div class="empty-state">
                No messages yet. Add the first one!
            </div>
        `;
        return;
    }

    // Sort from newest to oldest
    const sortedMessages = [...messages].reverse();

    messagesList.innerHTML = sortedMessages.map(msg => `
        <div class="message">
            <div class="message-text">${escapeHtml(msg.text)}</div>
            <div class="message-meta">
                <span>🕐 ${formatTimestamp(msg.timestamp)}</span>
                <span>🖥️ ${msg.hostname}</span>
                <span>#${msg.id}</span>
            </div>
        </div>
    `).join('');
}

// Add message
async function addMessage(text) {
    try {
        const response = await fetch(`${API_URL}/api/messages`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ text })
        });

        if (!response.ok) {
            throw new Error('Failed to add message');
        }

        const data = await response.json();

        // Refresh message list
        await loadMessages();

        // Clear input
        messageInput.value = '';

        // Show success (optional)
        console.log('Message added:', data);
    } catch (error) {
        console.error('Error adding message:', error);
        alert('Error adding message: ' + error.message);
    }
}

// Format timestamp
function formatTimestamp(timestamp) {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;

    // Less than a minute ago
    if (diff < 60000) {
        return 'just now';
    }

    // Less than an hour ago
    if (diff < 3600000) {
        const minutes = Math.floor(diff / 60000);
        return `${minutes} min ago`;
    }

    // Today
    if (date.toDateString() === now.toDateString()) {
        return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    }

    // Full date
    return date.toLocaleString('en-US', {
        day: '2-digit',
        month: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Escape HTML (security)
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Event listeners
messageForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const text = messageInput.value.trim();
    if (!text) return;

    await addMessage(text);
});

refreshBtn.addEventListener('click', () => {
    loadMessages();
});

// Auto-refresh co 10 sekund
setInterval(() => {
    if (!isLoading) {
        loadMessages();
    }
}, 10000);

// Inicjalizacja
(async () => {
    await checkApiStatus();
    await loadMessages();
})();
