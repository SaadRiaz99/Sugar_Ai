/* ============================================
   SUGAR TRACKER - App Logic
   ============================================ */

const STORAGE_KEY = 'sugar_tracker_readings';
const REMINDER_KEY = 'sugar_tracker_reminder';
let chart = null;
let reminderInterval = null;

// ============ INIT ============
document.addEventListener('DOMContentLoaded', () => {
  // Hide splash after animation
  setTimeout(() => {
    const splash = document.getElementById('splash');
    splash.style.display = 'none';
    document.getElementById('app').classList.remove('hidden');
    init();
  }, 4000);
});

function init() {
  setGreeting();
  renderAll();
  loadReminder();
  startReminderCheck();
  requestNotificationPermission();
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }
}

function setGreeting() {
  const h = new Date().getHours();
  let greet = 'Good Evening';
  if (h < 12) greet = 'Good Morning';
  else if (h < 17) greet = 'Good Afternoon';
  document.getElementById('greeting').textContent = greet + ' 👋';
}

// ============ STORAGE ============
function getReadings() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY)) || [];
  } catch {
    return [];
  }
}

function saveToStorage(readings) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(readings));
}

// ============ LEVELS ============
function getLevel(val) {
  if (val < 70) return 'low';
  if (val <= 140) return 'normal';
  if (val <= 200) return 'warning';
  return 'high';
}

function getStatusText(level) {
  switch (level) {
    case 'low': return 'Low - Eat carbs!';
    case 'normal': return 'Normal - Great!';
    case 'warning': return 'Borderline High';
    case 'high': return 'High - See Doctor!';
    default: return 'No data';
  }
}

// ============ SAVE READING ============
function saveReading() {
  const input = document.getElementById('sugarInput');
  const val = parseInt(input.value);
  const timing = document.querySelector('input[name="timing"]:checked')?.value || 'Fasting';
  const note = document.getElementById('noteInput').value.trim();

  if (!val || val < 20 || val > 600) {
    showToast('Please enter a valid reading (20-600)', true);
    input.focus();
    return;
  }

  const reading = {
    id: Date.now(),
    value: val,
    timing,
    note,
    date: new Date().toISOString()
  };

  const readings = getReadings();
  readings.unshift(reading);
  saveToStorage(readings);

  input.value = '';
  document.getElementById('noteInput').value = '';
  closeModal();
  renderAll();
  showToast('Reading saved!');
}

// ============ DELETE ============
function deleteReading(id) {
  const readings = getReadings().filter(r => r.id !== id);
  saveToStorage(readings);
  renderAll();
}

function clearAllData() {
  document.getElementById('confirmDialog').classList.remove('hidden');
}

function confirmClose() {
  document.getElementById('confirmDialog').classList.add('hidden');
}

function confirmClear() {
  localStorage.removeItem(STORAGE_KEY);
  document.getElementById('confirmDialog').classList.add('hidden');
  renderAll();
  showToast('All data cleared');
}

// ============ RENDER ALL ============
function renderAll() {
  const readings = getReadings();
  renderSummary(readings);
  renderHistory(readings);
  renderChart(readings);
  renderClearBtn(readings);

  // Diet advice based on last reading
  const lastReading = readings[0] || null;
  if (typeof renderDietAdvice === 'function') {
    renderDietAdvice(lastReading);
  }
}

function renderSummary(readings) {
  const today = new Date().toDateString();
  const todayReadings = readings.filter(r => new Date(r.date).toDateString() === today);
  const lastToday = todayReadings[0];

  const todayValEl = document.getElementById('todayValue');
  const todayStatusEl = document.getElementById('todayStatus');

  if (lastToday) {
    todayValEl.textContent = lastToday.value;
    const level = getLevel(lastToday.value);
    todayStatusEl.textContent = getStatusText(level);
    todayStatusEl.className = 'card-status status-' + level;
  } else {
    todayValEl.textContent = '--';
    todayStatusEl.textContent = 'No data yet';
    todayStatusEl.className = 'card-status';
  }

  // Counts
  const levels = readings.map(r => getLevel(r.value));
  document.getElementById('normalCount').textContent = levels.filter(l => l === 'normal').length;
  document.getElementById('highCount').textContent = levels.filter(l => l === 'high' || l === 'warning').length;
  document.getElementById('lowCount').textContent = levels.filter(l => l === 'low').length;
}

function renderHistory(readings) {
  const container = document.getElementById('historyList');

  if (readings.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">📊</div>
        <p>No readings yet</p>
        <p class="empty-sub">Tap + to add your first reading</p>
      </div>`;
    return;
  }

  const recent = readings.slice(0, 50);
  container.innerHTML = recent.map(r => {
    const level = getLevel(r.value);
    const d = new Date(r.date);
    const time = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const date = d.toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' });
    const noteHtml = r.note ? `<div class="history-note">"${r.note}"</div>` : '';

    return `
      <div class="history-item level-${level}">
        <div class="history-value val-${level}">${r.value}</div>
        <div class="history-info">
          <div class="history-timing">${r.timing}</div>
          <div class="history-date">${time} - ${date}</div>
          ${noteHtml}
        </div>
        <button class="history-delete" onclick="deleteReading(${r.id})" title="Delete">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
        </button>
      </div>`;
  }).join('');
}

function renderClearBtn(readings) {
  document.getElementById('clearBtn').style.display = readings.length > 0 ? 'block' : 'none';
}

// ============ CHART ============
function renderChart(readings) {
  const canvas = document.getElementById('chart');
  if (chart) chart.destroy();

  // Last 7 days
  const days = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    days.push(d);
  }

  const labels = days.map(d => d.toLocaleDateString([], { weekday: 'short' }));
  const avgData = days.map(day => {
    const dayStr = day.toDateString();
    const dayReadings = readings.filter(r => new Date(r.date).toDateString() === dayStr);
    if (dayReadings.length === 0) return null;
    return Math.round(dayReadings.reduce((s, r) => s + r.value, 0) / dayReadings.length);
  });

  const colors = avgData.map(v => {
    if (v === null) return 'rgba(0, 191, 166, 0.15)';
    const l = getLevel(v);
    if (l === 'normal') return '#4caf50';
    if (l === 'high') return '#ff5252';
    if (l === 'warning') return '#ff9100';
    return '#eab308';
  });

  chart = new Chart(canvas, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        data: avgData,
        backgroundColor: colors,
        borderRadius: 8,
        borderSkipped: false,
        barThickness: 28,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: '#132238',
          titleColor: '#f1f5f9',
          bodyColor: '#94a3b8',
          borderColor: 'rgba(142, 175, 196, 0.1)',
          borderWidth: 1,
          cornerRadius: 8,
          padding: 10,
          callbacks: {
            label: ctx => ctx.parsed.y !== null ? ctx.parsed.y + ' mg/dL' : 'No data'
          }
        }
      },
      scales: {
        x: {
          grid: { display: false },
          ticks: { color: '#5a7d96', font: { size: 11 } },
          border: { display: false }
        },
        y: {
          min: 0,
          max: 300,
          grid: { color: 'rgba(142, 175, 196, 0.06)' },
          ticks: { color: '#5a7d96', font: { size: 11 }, stepSize: 50 },
          border: { display: false }
        }
      }
    }
  });
}

// ============ EXPORT ============
function exportData() {
  const readings = getReadings();
  if (readings.length === 0) {
    showToast('No data to export', true);
    return;
  }

  let csv = 'Date,Time,Timing,Value (mg/dL),Level,Notes\n';
  readings.forEach(r => {
    const d = new Date(r.date);
    const date = d.toLocaleDateString();
    const time = d.toLocaleTimeString();
    const level = getLevel(r.value);
    csv += `"${date}","${time}","${r.timing}",${r.value},"${level}","${r.note || ''}"\n`;
  });

  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `sugar-tracker-${new Date().toLocaleDateString().replace(/\//g, '-')}.csv`;
  a.click();
  URL.revokeObjectURL(url);
  showToast('Data exported!');
}

// ============ MODAL ============
function openModal() {
  document.getElementById('modal').classList.remove('hidden');
  setTimeout(() => document.getElementById('sugarInput').focus(), 300);
}

function closeModal(e) {
  if (e && e.target !== e.currentTarget) return;
  document.getElementById('modal').classList.add('hidden');
}

function closeConfirm(e) {
  if (e && e.target !== e.currentTarget) return;
  document.getElementById('confirmDialog').classList.add('hidden');
}

// ============ TOAST ============
function showToast(msg, isError = false) {
  const existing = document.querySelector('.toast');
  if (existing) existing.remove();

  const toast = document.createElement('div');
  toast.className = 'toast' + (isError ? ' toast-error' : '');
  toast.textContent = msg;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 2500);
}

// ============ REMINDERS ============
function requestNotificationPermission() {
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
  }
}

function toggleReminder() {
  const enabled = document.getElementById('reminderToggle').checked;
  const timesDiv = document.getElementById('reminderTimes');
  const statusEl = document.getElementById('reminderStatus');

  if (enabled) {
    timesDiv.style.display = 'block';
    statusEl.textContent = 'Reminders active';
    statusEl.style.color = 'var(--green)';
    saveReminderTimes();
    startReminderCheck();
    showToast('Reminders enabled!');
  } else {
    timesDiv.style.display = 'none';
    statusEl.textContent = 'Not set';
    statusEl.style.color = '';
    localStorage.removeItem(REMINDER_KEY);
    if (reminderInterval) clearInterval(reminderInterval);
    showToast('Reminders disabled');
  }
}

function saveReminderTimes() {
  const data = {
    enabled: document.getElementById('reminderToggle').checked,
    morning: document.getElementById('remMorning').value,
    afternoon: document.getElementById('remAfternoon').value,
    evening: document.getElementById('remEvening').value,
    lastNotified: {}
  };
  localStorage.setItem(REMINDER_KEY, JSON.stringify(data));
}

function loadReminder() {
  try {
    const data = JSON.parse(localStorage.getItem(REMINDER_KEY));
    if (data && data.enabled) {
      document.getElementById('reminderToggle').checked = true;
      document.getElementById('reminderTimes').style.display = 'block';
      document.getElementById('remMorning').value = data.morning || '07:00';
      document.getElementById('remAfternoon').value = data.afternoon || '13:00';
      document.getElementById('remEvening').value = data.evening || '20:00';
      document.getElementById('reminderStatus').textContent = 'Reminders active';
      document.getElementById('reminderStatus').style.color = 'var(--green)';
    }
  } catch {}
}

function startReminderCheck() {
  if (reminderInterval) clearInterval(reminderInterval);
  reminderInterval = setInterval(checkReminders, 60000); // check every minute
}

function checkReminders() {
  try {
    const data = JSON.parse(localStorage.getItem(REMINDER_KEY));
    if (!data || !data.enabled) return;

    const now = new Date();
    const currentTime = now.getHours().toString().padStart(2, '0') + ':' +
                        now.getMinutes().toString().padStart(2, '0');
    const todayKey = now.toDateString();

    const times = [
      { key: 'morning', time: data.morning },
      { key: 'afternoon', time: data.afternoon },
      { key: 'evening', time: data.evening }
    ];

    for (const t of times) {
      if (t.time === currentTime) {
        const notifKey = t.key + '_' + todayKey;
        if (data.lastNotified && data.lastNotified[notifKey]) continue;

        sendNotification('Sugar Tracker Reminder', `Time to check your blood sugar level! (${t.key})`);

        if (!data.lastNotified) data.lastNotified = {};
        data.lastNotified[notifKey] = true;
        localStorage.setItem(REMINDER_KEY, JSON.stringify(data));
      }
    }
  } catch {}
}

function sendNotification(title, body) {
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, {
      body,
      icon: 'icon-192.svg',
      badge: 'icon-192.svg',
      vibrate: [200, 100, 200]
    });
  }
}

// ============ KEYBOARD ============
document.addEventListener('keydown', e => {
  if (e.key === 'Enter') {
    const modal = document.getElementById('modal');
    if (!modal.classList.contains('hidden')) {
      saveReading();
    }
  }
});
