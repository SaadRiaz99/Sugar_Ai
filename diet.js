/* ============================================
   DIET ADVISOR - Based on Sugar Level Algorithm
   ============================================ */

// Food database with glycemic index info
const FOOD_DB = {
  // HIGH GI FOODS (BAD for diabetics - avoid when high)
  highGI: [
    { name: 'White Rice (Chawal)', gi: 73, avoid: 'high', emoji: '🍚' },
    { name: 'White Bread (Double Roti)', gi: 75, avoid: 'high', emoji: '🍞' },
    { name: 'Sugar (Cheeni)', gi: 65, avoid: 'always', emoji: '🧂' },
    { name: 'Mithai / Sweets', gi: 80, avoid: 'always', emoji: '🍬' },
    { name: 'Cold Drinks / Soda', gi: 70, avoid: 'always', emoji: '🥤' },
    { name: 'Juices (Packaged)', gi: 68, avoid: 'high', emoji: '🧃' },
    { name: 'White Pasta', gi: 72, avoid: 'high', emoji: '🍝' },
    { name: 'Naan / Refined Flour', gi: 71, avoid: 'high', emoji: '🫓' },
    { name: 'Potatoes (Aloo) Fried', gi: 78, avoid: 'high', emoji: '🥔' },
    { name: 'Breakfast Cereal', gi: 74, avoid: 'high', emoji: '🥣' },
    { name: 'Banana (Kela) - Ripe', gi: 62, avoid: 'warning', emoji: '🍌' },
    { name: 'Mango (Aam)', gi: 56, avoid: 'warning', emoji: '🥭' },
    { name: 'Watermelon (Tarbooz)', gi: 72, avoid: 'high', emoji: '🍉' },
  ],

  // MEDIUM GI FOODS (moderate - be careful)
  medGI: [
    { name: 'Brown Rice', gi: 50, avoid: 'warning', emoji: '🍚' },
    { name: 'Roti (Whole Wheat)', gi: 45, avoid: 'normal', emoji: '🫓' },
    { name: 'Oatmeal (Daliya)', gi: 55, avoid: 'normal', emoji: '🥣' },
    { name: 'Apple (Saib)', gi: 36, avoid: 'normal', emoji: '🍎' },
    { name: 'Orange (Malta)', gi: 43, avoid: 'normal', emoji: '🍊' },
    { name: 'Chapati', gi: 47, avoid: 'normal', emoji: '🫓' },
    { name: 'Sweet Potato (Shakar Qandi)', gi: 61, avoid: 'warning', emoji: '🍠' },
    { name: 'Pineapple (Ananas)', gi: 59, avoid: 'warning', emoji: '🍍' },
    { name: 'Papaya (Papeeta)', gi: 58, avoid: 'warning', emoji: '🍈' },
  ],

  // LOW GI FOODS (GOOD - safe to eat)
  lowGI: [
    { name: 'Lentils (Daal)', gi: 29, avoid: 'safe', emoji: '🫘' },
    { name: 'Chickpeas (Chana)', gi: 28, avoid: 'safe', emoji: '🫘' },
    { name: 'Green Vegetables (Sabzi)', gi: 15, avoid: 'safe', emoji: '🥬' },
    { name: 'Spinach (Palak)', gi: 15, avoid: 'safe', emoji: '🥬' },
    { name: 'Cucumber (Kheera)', gi: 15, avoid: 'safe', emoji: '🥒' },
    { name: 'Tomato (Tamatar)', gi: 15, avoid: 'safe', emoji: '🍅' },
    { name: 'Egg (Anda)', gi: 0, avoid: 'safe', emoji: '🥚' },
    { name: 'Chicken (Murghi)', gi: 0, avoid: 'safe', emoji: '🍗' },
    { name: 'Fish (Machli)', gi: 0, avoid: 'safe', emoji: '🐟' },
    { name: 'Almonds (Badam)', gi: 15, avoid: 'safe', emoji: '🥜' },
    { name: 'Walnut (Akhrot)', gi: 15, avoid: 'safe', emoji: '🥜' },
    { name: 'Guava (Amrood)', gi: 12, avoid: 'safe', emoji: '🍈' },
    { name: 'Avocado', gi: 15, avoid: 'safe', emoji: '🥑' },
    { name: 'Olive Oil (Zaitoon ka Tel)', gi: 0, avoid: 'safe', emoji: '🫒' },
    { name: 'Butter (Makhan) - Little', gi: 0, avoid: 'safe', emoji: '🧈' },
    { name: 'Yogurt (Dahi)', gi: 12, avoid: 'safe', emoji: '🥛' },
    { name: 'Milk (Doodh)', gi: 30, avoid: 'normal', emoji: '🥛' },
    { name: 'Lassi (Unsweetened)', gi: 20, avoid: 'safe', emoji: '🥛' },
    { name: 'Barley (Jou)', gi: 28, avoid: 'safe', emoji: '🌾' },
    { name: 'Flax Seeds (Alsi)', gi: 10, avoid: 'safe', emoji: '🌰' },
  ]
};

const WATER_ADVICE = {
  high: 'Drink 8-10 glasses of water daily. Add lemon (no sugar).',
  warning: 'Drink 6-8 glasses. Stay hydrated.',
  normal: 'Good hydration helps maintain sugar levels.',
  low: 'Drink water immediately if feeling dizzy. Eat a sweet fruit.'
};

const EXERCISE_ADVICE = {
  high: 'Walk 30 minutes after every meal. Light exercise helps lower sugar.',
  warning: 'Walk 20-30 minutes daily. Avoid intense exercise.',
  normal: 'Continue regular walking. 30 min daily is ideal.',
  low: 'Avoid exercise right now. Eat something first, then walk later.'
};

function getDietAdvice(level, lastReading) {
  const advice = {
    level,
    foodsToAvoid: [],
    foodsToEat: [],
    waterAdvice: WATER_ADVICE[level],
    exerciseAdvice: EXERCISE_ADVICE[level],
    mealSuggestion: '',
    alertMessage: ''
  };

  // Algorithm: decide what to show based on sugar level
  switch (level) {
    case 'low':
      // LOW SUGAR - need fast-acting carbs
      advice.alertMessage = '⚠️ Your sugar is LOW! Eat something sweet immediately.';
      advice.mealSuggestion = 'Eat glucose tablets, or 2-3 spoons of sugar in water, or a banana right now.';
      advice.foodsToAvoid = [
        { name: 'Exercise without eating', emoji: '🏃' },
        { name: 'Skipping meals', emoji: '⏰' },
        { name: 'Alcohol', emoji: '🍷' },
      ];
      advice.foodsToEat = [
        { name: 'Glucose tablets', emoji: '💊', reason: 'Fast sugar boost' },
        { name: '2-3 dates (Khajoor)', emoji: '🫘', reason: 'Natural quick sugar' },
        { name: 'Banana (Kela)', emoji: '🍌', reason: 'Quick energy' },
        { name: 'Sugar in water', emoji: '🥤', reason: 'Immediate relief' },
        { name: 'Juice (fresh)', emoji: '🧃', reason: 'Fast acting carbs' },
      ];
      break;

    case 'high':
      // HIGH SUGAR - strict avoidance
      advice.alertMessage = '🔴 Sugar is HIGH! Avoid all sugary and starchy foods today.';
      advice.mealSuggestion = 'Eat boiled chicken/fish with green salad. No rice or roti today.';
      advice.foodsToAvoid = FOOD_DB.highGI.map(f => ({
        name: f.name,
        emoji: f.emoji,
        reason: `GI: ${f.gi} (raises sugar fast)`
      }));
      advice.foodsToEat = FOOD_DB.lowGI.filter(f => f.gi <= 15).map(f => ({
        name: f.name,
        emoji: f.emoji,
        reason: `GI: ${f.gi} (safe)`
      }));
      break;

    case 'warning':
      // BORDERLINE - moderate caution
      advice.alertMessage = '🟡 Sugar is borderline. Be careful with food choices.';
      advice.mealSuggestion = 'Eat half portion of roti/rice. Add extra salad and daal.';
      advice.foodsToAvoid = FOOD_DB.highGI.filter(f => f.avoid !== 'normal').map(f => ({
        name: f.name,
        emoji: f.emoji,
        reason: `GI: ${f.gi} (may raise sugar)`
      }));
      advice.foodsToEat = [
        ...FOOD_DB.lowGI.slice(0, 8).map(f => ({
          name: f.name, emoji: f.emoji, reason: `GI: ${f.gi}`
        })),
        ...FOOD_DB.medGI.filter(f => f.gi < 50).map(f => ({
          name: f.name, emoji: f.emoji, reason: `GI: ${f.gi} (moderate)`
        }))
      ];
      break;

    case 'normal':
      // NORMAL - maintain healthy habits
      advice.alertMessage = '✅ Sugar is normal! Keep up the good work.';
      advice.mealSuggestion = 'Balanced diet. 2 roti + daal + sabzi + salad is perfect.';
      advice.foodsToAvoid = FOOD_DB.highGI.filter(f => f.avoid === 'always').map(f => ({
        name: f.name,
        emoji: f.emoji,
        reason: 'Always avoid (high sugar risk)'
      }));
      advice.foodsToEat = FOOD_DB.medGI.slice(0, 5).map(f => ({
        name: f.name, emoji: f.emoji, reason: `GI: ${f.gi} (moderate - OK)`
      }));
      break;
  }

  return advice;
}

function renderDietAdvice(lastReading) {
  const container = document.getElementById('dietAdvice');
  if (!lastReading) {
    container.innerHTML = `
      <div class="diet-placeholder">
        <div class="empty-icon">🍽️</div>
        <p>Add a reading to see food advice</p>
      </div>`;
    return;
  }

  const level = getLevel(lastReading.value);
  const advice = getDietAdvice(level, lastReading);

  let html = '';

  // Alert
  html += `<div class="diet-alert diet-alert-${level}">${advice.alertMessage}</div>`;

  // Meal suggestion
  html += `<div class="diet-meal">
    <div class="diet-meal-title">📋 Today's Meal Plan</div>
    <p>${advice.mealSuggestion}</p>
  </div>`;

  // Foods to avoid
  if (advice.foodsToAvoid.length > 0) {
    html += `<div class="diet-group">
      <h3 class="diet-group-title avoid">❌ Foods to Avoid</h3>
      <div class="food-list">${advice.foodsToAvoid.map(f =>
        `<div class="food-item food-avoid">
          <span class="food-emoji">${f.emoji}</span>
          <div class="food-info">
            <span class="food-name">${f.name}</span>
            <span class="food-reason">${f.reason}</span>
          </div>
        </div>`
      ).join('')}</div>
    </div>`;
  }

  // Foods to eat
  if (advice.foodsToEat.length > 0) {
    html += `<div class="diet-group">
      <h3 class="diet-group-title safe">✅ Recommended Foods</h3>
      <div class="food-list">${advice.foodsToEat.map(f =>
        `<div class="food-item food-safe">
          <span class="food-emoji">${f.emoji}</span>
          <div class="food-info">
            <span class="food-name">${f.name}</span>
            <span class="food-reason">${f.reason}</span>
          </div>
        </div>`
      ).join('')}</div>
    </div>`;
  }

  // Water & Exercise
  html += `<div class="diet-tips">
    <div class="diet-tip">
      <span>💧</span>
      <p>${advice.waterAdvice}</p>
    </div>
    <div class="diet-tip">
      <span>🚶</span>
      <p>${advice.exerciseAdvice}</p>
    </div>
  </div>`;

  container.innerHTML = html;
}
