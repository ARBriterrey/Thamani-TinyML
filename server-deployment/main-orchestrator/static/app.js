// ─── DOM Elements ────────────────────────────────────────────────────────
const form = document.getElementById('sensorForm');
const submitBtn = document.getElementById('submitBtn');

const resultIdle = document.getElementById('resultIdle');
const resultLoading = document.getElementById('resultLoading');
const resultOutput = document.getElementById('resultOutput');
const resultError = document.getElementById('resultError');

const serverStatus = document.getElementById('serverStatus');
const statusLabel = serverStatus.querySelector('.status-label');

const API_BASE = window.location.origin;

// ─── Initialization ────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  checkServerHealth();
  setInterval(checkServerHealth, 30000); // Check every 30s
});

async function checkServerHealth() {
  try {
    const res = await fetch(`${API_BASE}/api/health`, { timeout: 5000 });
    if (res.ok) {
      serverStatus.classList.remove('offline');
      serverStatus.classList.add('online');
      statusLabel.textContent = 'API Online';
    } else {
      throw new Error('Not OK');
    }
  } catch (err) {
    serverStatus.classList.remove('online');
    serverStatus.classList.add('offline');
    statusLabel.textContent = 'API Offline';
  }
}

// ─── Form Submission ───────────────────────────────────────────────────
form.addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const payload = {
    device_id: document.getElementById('deviceId').value || 'DEV-001',
    sensor_data: {
      heart_rate: parseInt(document.getElementById('heartRate').value),
      spo2: parseInt(document.getElementById('spo2').value),
      temperature: parseFloat(document.getElementById('temperature').value),
      systolic_bp: parseInt(document.getElementById('systolicBp').value),
      diastolic_bp: parseInt(document.getElementById('diastolicBp').value)
    }
  };

  showLoadingState();

  try {
    const response = await fetch(`${API_BASE}/api/process`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Server error occurred');
    }

    animateSteps(data);
    
  } catch (err) {
    showErrorState(err.message);
  }
});

// ─── UI Transitions ────────────────────────────────────────────────────
function showLoadingState() {
  resultIdle.classList.add('hidden');
  resultOutput.classList.add('hidden');
  resultError.classList.add('hidden');
  resultLoading.classList.remove('hidden');
  submitBtn.disabled = true;

  // Reset steps
  document.querySelectorAll('.step').forEach(s => {
    s.classList.remove('step-done', 'step-active');
    if(s.id === 'step1') {
      s.classList.add('step-done');
    } else {
      s.classList.add('dim');
      s.textContent = s.textContent.replace('✅', '').trim();
    }
  });
}

function showErrorState(msg) {
  resultLoading.classList.add('hidden');
  resultError.classList.remove('hidden');
  document.getElementById('errorMsg').textContent = msg;
  submitBtn.disabled = false;
}

// Emulate steps processing visually (since our API is blocking, we just fake the timeline to look cool)
function animateSteps(finalData) {
  const steps = [
    { id: 'step2', text: '✅ Saved to shared volume', delay: 400 },
    { id: 'step3', text: '✅ Worker container spun up', delay: 1000 },
    { id: 'step4', text: '✅ MATLAB engine execution complete', delay: 1800 },
    { id: 'step5', text: '✅ Results retrieved', delay: 2200 }
  ];

  steps.forEach(step => {
    setTimeout(() => {
      const el = document.getElementById(step.id);
      el.classList.remove('dim');
      el.classList.add('step-done');
      // replace icon
      el.textContent = step.text;
    }, step.delay);
  });

  // Finally show results
  setTimeout(() => {
    renderResults(finalData);
  }, 2600);
}

// ─── Render Results ────────────────────────────────────────────────────
function renderResults(data) {
  resultLoading.classList.add('hidden');
  resultOutput.classList.remove('hidden');
  submitBtn.disabled = false;

  const result = data.result;
  
  // 1. Update Gauge
  const targetScore = result.risk_score;
  animateValue("gaugeScore", 0, targetScore, 1000);
  
  // The circle circumference is 251.2
  const offset = 251.2 - (251.2 * (targetScore / 100));
  const progressPath = document.getElementById('gaugeProgress');
  progressPath.style.strokeDashoffset = 251.2; // reset
  setTimeout(() => { progressPath.style.strokeDashoffset = offset; }, 100);

  // 2. Category Badge
  const badge = document.getElementById('categoryBadge');
  badge.textContent = `${result.risk_category} RISK`;
  badge.className = 'category-badge'; // reset
  badge.classList.add(`category-${result.risk_category.toLowerCase()}`);

  // 3. Flags
  const flagsList = document.getElementById('flagsList');
  flagsList.innerHTML = '';
  if (result.clinical_flags && result.clinical_flags.length > 0) {
    result.clinical_flags.forEach(flag => {
      const span = document.createElement('span');
      span.className = 'flag-tag';
      span.textContent = flag.replace(/_/g, ' ').toUpperCase();
      flagsList.appendChild(span);
    });
  } else {
    flagsList.innerHTML = '<span class="no-flags">No critical flags detected.</span>';
  }

  // 4. Stats Grid
  const grid = document.getElementById('statsGrid');
  grid.innerHTML = `
    <div class="stat-card">
      <p class="stat-label">Parameters</p>
      <p class="stat-value">${result.parameters_analyzed || 5}</p>
    </div>
    <div class="stat-card">
      <p class="stat-label">Engine</p>
      <p class="stat-value">${data.processing_engine || 'matlab-mcr'}</p>
    </div>
  `;

  // 5. Meta
  const meta = document.getElementById('metaRow');
  const d = new Date(data.processed_at || new Date());
  meta.innerHTML = `Job ID: <span>${data.job_id.split('-')[0]}...</span> • Time: <span>${d.toLocaleTimeString()}</span>`;

  // 6. Raw
  document.getElementById('rawJson').textContent = JSON.stringify(data, null, 2);

  // 7. Add to History
  addToHistory(data);
}

// ─── History ───────────────────────────────────────────────────────────
function addToHistory(data) {
  const list = document.getElementById('historyList');
  const empty = list.querySelector('.empty-history');
  if (empty) empty.remove();

  const el = document.createElement('div');
  el.className = 'history-item';
  
  const d = new Date(data.processed_at || new Date());
  const score = data.result.risk_score;
  const cat = data.result.risk_category.toLowerCase();

  let color = 'var(--text-muted)';
  if (cat === 'high') color = 'var(--red)';
  if (cat === 'moderate') color = 'var(--amber)';
  if (cat === 'low') color = 'var(--green)';

  el.innerHTML = `
    <div class="h-left">
      <span class="h-device">${data.device_id}</span>
      <span class="h-id">${data.job_id.substring(0,8)} • ${d.toLocaleTimeString()}</span>
    </div>
    <div class="h-badge" style="color: ${color}; border: 1px solid ${color};">
      Score: ${score}
    </div>
  `;

  list.insertBefore(el, list.firstChild);
  if (list.children.length > 5) list.lastChild.remove();
}

// ─── Helpers ───────────────────────────────────────────────────────────
function applyPreset(type) {
  const vals = {
    low: { hr: 72, spo2: 98, temp: 36.6, sys: 120, dia: 80 },
    moderate: { hr: 105, spo2: 94, temp: 37.8, sys: 135, dia: 88 },
    high: { hr: 140, spo2: 88, temp: 39.5, sys: 160, dia: 95 }
  };
  const v = vals[type];

  document.getElementById('heartRate').value = v.hr;
  document.getElementById('spo2').value = v.spo2;
  document.getElementById('temperature').value = v.temp;
  document.getElementById('systolicBp').value = v.sys;
  document.getElementById('diastolicBp').value = v.dia;

  // trigger updates
  document.querySelectorAll('input[type=range]').forEach(el => el.dispatchEvent(new Event('input')));
}

function animateValue(id, start, end, duration) {
  const obj = document.getElementById(id);
  let startTimestamp = null;
  const step = (timestamp) => {
    if (!startTimestamp) startTimestamp = timestamp;
    const progress = Math.min((timestamp - startTimestamp) / duration, 1);
    obj.innerHTML = (progress * (end - start) + start).toFixed(1);
    if (progress < 1) {
      window.requestAnimationFrame(step);
    }
  };
  window.requestAnimationFrame(step);
}

function toggleRaw() {
  document.getElementById('rawJson').classList.toggle('hidden');
}
