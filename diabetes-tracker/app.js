/* ============================================
   SUGAR TRACKER - App Logic
   ============================================ */

const STORAGE_KEY = 'sugar_tracker_readings';
const REMINDER_KEY = 'sugar_tracker_reminder';
const PROFILE_KEY = 'sugar_tracker_profile';
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
  loadProfile();
  checkAutoFillHint();
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
  renderHbA1c(readings);

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

  // Today stats
  const todayAvgEl = document.getElementById('todayAvg');
  const todayCountEl = document.getElementById('todayCount');
  const weekAvgEl = document.getElementById('weekAvg');

  if (todayReadings.length > 0) {
    const avg = Math.round(todayReadings.reduce((s, r) => s + r.value, 0) / todayReadings.length);
    todayAvgEl.textContent = avg;
    todayAvgEl.style.color = getLevel(avg) === 'normal' ? 'var(--green)' : getLevel(avg) === 'high' ? 'var(--red)' : getLevel(avg) === 'warning' ? 'var(--orange)' : 'var(--yellow)';
    todayCountEl.textContent = todayReadings.length;
  } else {
    todayAvgEl.textContent = '--';
    todayAvgEl.style.color = '';
    todayCountEl.textContent = '0';
  }

  // 7-day average
  const last7 = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dayStr = d.toDateString();
    const dayReadings = readings.filter(r => new Date(r.date).toDateString() === dayStr);
    dayReadings.forEach(r => last7.push(r.value));
  }
  if (last7.length > 0) {
    const wAvg = Math.round(last7.reduce((a, b) => a + b, 0) / last7.length);
    weekAvgEl.textContent = wAvg;
    weekAvgEl.style.color = getLevel(wAvg) === 'normal' ? 'var(--green)' : getLevel(wAvg) === 'high' ? 'var(--red)' : getLevel(wAvg) === 'warning' ? 'var(--orange)' : 'var(--yellow)';
  } else {
    weekAvgEl.textContent = '--';
    weekAvgEl.style.color = '';
  }
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
          backgroundColor: '#ffffff',
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

// ============ HBA1C ESTIMATOR ============
function renderHbA1c(readings) {
  const container = document.getElementById('hba1cResult');
  if (readings.length < 1) {
    container.innerHTML = `<div class="diet-placeholder"><div class="empty-icon">🧪</div><p>Add readings to estimate HbA1c</p></div>`;
    return;
  }

  // Use last 90 days or all readings
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 90);
  const recent = readings.filter(r => new Date(r.date) >= cutoff);

  if (recent.length === 0) {
    container.innerHTML = `<div class="diet-placeholder"><div class="empty-icon">🧪</div><p>No readings in last 90 days</p></div>`;
    return;
  }

  const avg = recent.reduce((s, r) => s + r.value, 0) / recent.length;
  // Formula: HbA1c = (avg + 46.7) / 28.7 (eAG to A1c)
  const hba1c = ((avg + 46.7) / 28.7).toFixed(1);
  const readingCount = recent.length;
  const daysCovered = Math.round((new Date() - new Date(recent[recent.length - 1].date)) / 86400000);

  let hba1cColor, hba1cStatus;
  if (hba1c < 5.7) { hba1cColor = 'var(--green)'; hba1cStatus = 'Normal'; }
  else if (hba1c < 6.5) { hba1cColor = 'var(--orange)'; hba1cStatus = 'Prediabetes'; }
  else if (hba1c < 7.0) { hba1cColor = '#f59e0b'; hba1cStatus = 'Diabetes (Controlled)'; }
  else if (hba1c < 8.0) { hba1cColor = 'var(--orange)'; hba1cStatus = 'Diabetes (Fair Control)'; }
  else { hba1cColor = 'var(--red)'; hba1cStatus = 'Diabetes (Poor Control)'; }

  container.innerHTML = `
    <div class="hba1c-header">
      <div class="hba1c-big" style="color:${hba1cColor}">${hba1c}%</div>
      <div class="hba1c-label">Estimated HbA1c</div>
      <div class="hba1c-status" style="color:${hba1cColor}">${hba1cStatus}</div>
    </div>
    <div class="hba1c-details">
      <div class="hba1c-row">
        <span class="hba1c-info-label">Average Glucose:</span>
        <span class="hba1c-info-val">${Math.round(avg)} mg/dL</span>
      </div>
      <div class="hba1c-row">
        <span class="hba1c-info-label">Readings Used:</span>
        <span class="hba1c-info-val">${readingCount} readings (last ${daysCovered} days)</span>
      </div>
      <div class="hba1c-row">
        <span class="hba1c-info-label">Formula:</span>
        <span class="hba1c-info-val">eAG = (Avg + 46.7) / 28.7</span>
      </div>
      <div class="hba1c-targets">
        <div class="hba1c-target"><span style="color:var(--green)">Normal</span>: &lt; 5.7%</div>
        <div class="hba1c-target"><span style="color:var(--orange)">Prediabetes</span>: 5.7 - 6.4%</div>
        <div class="hba1c-target"><span style="color:var(--red)">Diabetes</span>: &ge; 6.5%</div>
      </div>
    </div>
    <div class="formula-note">This is an estimate. For accurate HbA1c, get a lab test done.</div>
  `;
}

// ============ AUTO-FILL ============
function checkAutoFillHint() {
  const readings = getReadings();
  const last = readings[0];
  const hint = document.getElementById('autoFillHint');
  if (last && hint) {
    hint.style.display = 'inline';
  }
}

function autoFillInsulin() {
  const readings = getReadings();
  const last = readings[0];
  if (last) {
    document.getElementById('insulinBG').value = last.value;
    showToast('Auto-filled from last reading: ' + last.value);
  }
}

function setCarbs(grams) {
  document.getElementById('insulinCarbs').value = grams;
  document.querySelectorAll('.carb-preset-btn').forEach(btn => {
    btn.classList.toggle('active', btn.textContent.startsWith(grams));
  });
}

// ============ DOSE SAFETY INDICATOR ============
function getDoseSafety(dose, weight) {
  if (!weight) return { level: 'unknown', text: 'Enter weight for safety check', color: 'var(--text-muted)' };
  const perKg = dose / weight;
  if (perKg <= 0.5) return { level: 'safe', text: `Safe (${perKg.toFixed(2)} u/kg)`, color: 'var(--green)' };
  if (perKg <= 1.0) return { level: 'moderate', text: `Moderate (${perKg.toFixed(2)} u/kg)`, color: 'var(--orange)' };
  return { level: 'high', text: `High dose (${perKg.toFixed(2)} u/kg) - Consult doctor!`, color: 'var(--red)' };
}

// ============ WEIGHT PROFILE ============
function saveProfile() {
  if (!document.getElementById('saveProfileCheck')?.checked) return;
  const gender = document.querySelector('input[name="gender"]:checked')?.value || 'M';
  const weight = document.getElementById('weightInput').value;
  const height = document.getElementById('heightInput').value;
  if (weight && height) {
    localStorage.setItem(PROFILE_KEY, JSON.stringify({ gender, weight, height }));
  }
}

function loadProfile() {
  try {
    const data = JSON.parse(localStorage.getItem(PROFILE_KEY));
    if (data) {
      document.getElementById('weightInput').value = data.weight || '';
      document.getElementById('heightInput').value = data.height || '';
      const genderRadio = document.querySelector(`input[name="gender"][value="${data.gender}"]`);
      if (genderRadio) genderRadio.checked = true;
      document.getElementById('profileBar').style.display = 'flex';
    }
  } catch {}
}

function clearProfile() {
  localStorage.removeItem(PROFILE_KEY);
  document.getElementById('profileBar').style.display = 'none';
  showToast('Profile cleared');
}

// ============ INSULIN CALCULATOR ============
function calculateInsulin() {
  const bg = parseFloat(document.getElementById('insulinBG').value);
  const carbs = parseFloat(document.getElementById('insulinCarbs').value);
  const weight = parseFloat(document.getElementById('insulinWeight').value);
  const tdd = parseFloat(document.getElementById('insulinTDD').value);

  if (!bg || bg < 20 || bg > 600) {
    showToast('Enter valid blood sugar (20-600)', true);
    return;
  }

  const resultDiv = document.getElementById('insulinResult');
  resultDiv.classList.remove('hidden');

  const targetBG = 140;
  const carbRatio = tdd ? Math.round(tdd / carbs || 0) : 10;
  const correctionFactor = tdd ? Math.round(1800 / tdd) : 45;
  const avgDailyPerKg = weight ? (tdd / weight).toFixed(1) : '--';

  // After Meal Formula: (Carbs / ICR) + (BG - Target) / CF
  const carbDose = carbs ? (carbs / carbRatio).toFixed(1) : 0;
  const correctionDose = bg > targetBG ? ((bg - targetBG) / correctionFactor).toFixed(1) : 0;
  const afterMealTotal = (parseFloat(carbDose) + parseFloat(correctionDose)).toFixed(1);

  // Fast Insulin (Rapid-Acting like Lispro/Humalog)
  const onset = '15 min';
  const peak = '1-2 hours';
  const duration = '3-5 hours';

  // Average Basic Insulin (Basal like Glargine)
  const basalDose = tdd ? (tdd * 0.5).toFixed(1) : '--';
  const perKgBasal = weight ? (basalDose / weight || 0).toFixed(2) : '--';

  let level = getLevel(bg);
  let levelColor = level === 'normal' ? 'var(--green)' : level === 'high' ? 'var(--red)' : level === 'warning' ? 'var(--orange)' : 'var(--yellow)';

  // Safety indicator
  const safety = getDoseSafety(parseFloat(afterMealTotal), weight);

  resultDiv.innerHTML = `
    <div class="insulin-result-header" style="color:${levelColor}">
      Sugar Level: <strong>${level.toUpperCase()}</strong> (${bg} mg/dL)
    </div>

    <div class="insulin-formula-card">
      <div class="formula-title">After Meal Insulin (Rapid-Acting)</div>
      <div class="formula-box">
        <div class="formula-line">
          <span class="formula-label">Formula:</span>
          <span class="formula-text">(Carbs &divide; ICR) + (BG - Target) &divide; CF</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Carb Ratio (ICR):</span>
          <span class="formula-val">${carbRatio} (1u per ${carbRatio}g carbs)</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Correction Factor (CF):</span>
          <span class="formula-val">${correctionFactor} (1u drops BG by ${correctionFactor})</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Target BG:</span>
          <span class="formula-val">${targetBG} mg/dL</span>
        </div>
        <div class="formula-result">
          <span>Carb Dose: ${carbDose}u</span>
          <span> + </span>
          <span>Correction: ${correctionDose}u</span>
          <span> = </span>
          <strong>${afterMealTotal} units</strong>
        </div>
        <div class="dose-safety" style="border-left-color:${safety.color}">
          <span class="dose-safety-dot" style="background:${safety.color}"></span>
          Safety: <strong style="color:${safety.color}">${safety.text}</strong>
        </div>
      </div>
    </div>

    <div class="insulin-formula-card">
      <div class="formula-title">Fast-Acting Insulin (After Meal)</div>
      <div class="formula-box">
        <div class="formula-line">
          <span class="formula-label">Type:</span>
          <span class="formula-val">Rapid-Acting (Lispro / Humalog / NovoRapid)</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Onset:</span>
          <span class="formula-val">${onset}</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Peak:</span>
          <span class="formula-val">${peak}</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Duration:</span>
          <span class="formula-val">${duration}</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Recommended Dose:</span>
          <span class="formula-val"><strong>${afterMealTotal} units</strong> before or with meal</span>
        </div>
        <div class="formula-note">Take 15 min before eating for best results. Adjust based on food type.</div>
      </div>
    </div>

    <div class="insulin-formula-card">
      <div class="formula-title">Average Daily Insulin (Basal)</div>
      <div class="formula-box">
        <div class="formula-line">
          <span class="formula-label">Formula:</span>
          <span class="formula-text">TDD &times; 50% = Basal Dose</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Total Daily Dose (TDD):</span>
          <span class="formula-val">${tdd || '--'} units/day</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Basal (50% of TDD):</span>
          <span class="formula-val">${basalDose} units/day</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Per kg body weight:</span>
          <span class="formula-val">${avgDailyPerKg} u/kg/day</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Basal per kg:</span>
          <span class="formula-val">${perKgBasal} u/kg/day</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Type:</span>
          <span class="formula-val">Long-Acting (Glargine / Lantus / Levemir)</span>
        </div>
        <div class="formula-note">Usually taken once or twice daily. Normal range: 0.4-1.0 u/kg/day.</div>
      </div>
    </div>

    <div class="insulin-disclaimer">
      Disclaimer: This is for reference only. Always consult your doctor for exact dosage.
    </div>
  `;
}

// ============ WEIGHT RECOMMENDATION ============
function calculateWeight() {
  const currentWeight = parseFloat(document.getElementById('weightInput').value);
  const height = parseFloat(document.getElementById('heightInput').value);
  const sugar = parseFloat(document.getElementById('weightSugar').value);

  if (!currentWeight || !height) {
    showToast('Enter weight and height', true);
    return;
  }

  const resultDiv = document.getElementById('weightResult');
  resultDiv.classList.remove('hidden');

  // BMI Calculation
  const heightM = height / 100;
  const bmi = (currentWeight / (heightM * heightM)).toFixed(1);

  // Ideal Body Weight (IBW) - Devine Formula
  let ibw;
  const gender = document.querySelector('input[name="gender"]:checked')?.value || 'M';
  if (gender === 'M') {
    ibw = 50 + 2.3 * ((height / 2.54) - 60);
  } else {
    ibw = 45.5 + 2.3 * ((height / 2.54) - 60);
  }
  ibw = Math.round(ibw * 10) / 10;

  // Weight loss needed
  const weightDiff = Math.round((currentWeight - ibw) * 10) / 10;
  const weightStatus = weightDiff > 0 ? 'over' : weightDiff < 0 ? 'under' : 'at';

  // BMI Categories
  let bmiCategory, bmiColor;
  if (bmi < 18.5) { bmiCategory = 'Underweight'; bmiColor = 'var(--yellow)'; }
  else if (bmi < 25) { bmiCategory = 'Normal'; bmiColor = 'var(--green)'; }
  else if (bmi < 30) { bmiCategory = 'Overweight'; bmiColor = 'var(--orange)'; }
  else { bmiCategory = 'Obese'; bmiColor = 'var(--red)'; }

  // Sugar-based weight impact
  let sugarImpact = '';
  if (sugar) {
    if (sugar > 200) {
      sugarImpact = 'High sugar damages blood vessels. Weight loss of 5-10% can significantly reduce sugar levels.';
    } else if (sugar > 140) {
      sugarImpact = 'Borderline sugar. Losing 3-5 kg can help bring sugar to normal range.';
    } else if (sugar >= 70 && sugar <= 140) {
      sugarImpact = 'Good sugar level. Maintain current weight with balanced diet.';
    } else {
      sugarImpact = 'Low sugar. Avoid weight loss. Focus on regular meals and gaining healthy weight.';
    }
  }

  // Recommended weight range for diabetics
  const idealMin = Math.round(ibw - 3);
  const idealMax = Math.round(ibw + 3);

  // Per day calorie to reach goal
  const calDeficit = weightDiff > 0 ? Math.round(weightDiff * 7700 / 90) : 0;

  resultDiv.innerHTML = `
    <div class="weight-result-header">
      Your BMI: <strong style="color:${bmiColor}">${bmi}</strong> (${bmiCategory})
    </div>

    <div class="weight-formula-card">
      <div class="formula-title">BMI Formula</div>
      <div class="formula-box">
        <div class="formula-line">
          <span class="formula-label">Formula:</span>
          <span class="formula-text">Weight (kg) &divide; Height (m)&sup2;</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Calculation:</span>
          <span class="formula-val">${currentWeight} &divide; ${heightM}&sup2; = <strong>${bmi}</strong></span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Category:</span>
          <span class="formula-val" style="color:${bmiColor}"><strong>${bmiCategory}</strong></span>
        </div>
      </div>
    </div>

    <div class="weight-formula-card">
      <div class="formula-title">Ideal Body Weight (Devine Formula)</div>
      <div class="formula-box">
        <div class="formula-line">
          <span class="formula-label">Formula (${gender}):</span>
          <span class="formula-text">${gender === 'M' ? '50 + 2.3 &times; (Height(in) - 60)' : '45.5 + 2.3 &times; (Height(in) - 60)'}</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Ideal Weight:</span>
          <span class="formula-val"><strong>${ibw} kg</strong></span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Ideal Range:</span>
          <span class="formula-val">${idealMin} - ${idealMax} kg</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">You are:</span>
          <span class="formula-val">${Math.abs(weightDiff)} kg ${weightStatus} ideal weight</span>
        </div>
      </div>
    </div>

    ${sugar ? `
    <div class="weight-formula-card">
      <div class="formula-title">Sugar &amp; Weight Impact</div>
      <div class="formula-box">
        <div class="formula-line">
          <span class="formula-label">Latest Sugar:</span>
          <span class="formula-val"><strong>${sugar} mg/dL</strong> (${getLevel(sugar).toUpperCase()})</span>
        </div>
        <div class="formula-note">${sugarImpact}</div>
        ${weightDiff > 0 ? `
        <div class="formula-line">
          <span class="formula-label">Weight Goal:</span>
          <span class="formula-val">Lose ${Math.abs(weightDiff)} kg to reach ideal weight</span>
        </div>
        <div class="formula-line">
          <span class="formula-label">Calorie Deficit:</span>
          <span class="formula-val">~${calDeficit} kcal/day deficit needed (over 3 months)</span>
        </div>
        ` : ''}
      </div>
    </div>
    ` : ''}

    <div class="insulin-disclaimer">
      Disclaimer: These are general guidelines. Consult your doctor or dietitian for personalized advice.
    </div>
  `;

  saveProfile();
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
