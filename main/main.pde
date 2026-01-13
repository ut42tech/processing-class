// シンプル生態系シミュレーション
// Prey（被食者）とPredator（捕食者）の相互作用

// ================================================================
// 調整用パラメータ（バランス調整用）
// ================================================================

// 初期個体数
int initialPreyCount = 80;
int initialPredatorCount = 15;

// Prey（被食者/草食）のパラメータ
float preyMaxSpeed = 2.5;
float preySize = 6;
float preyInitialEnergy = 100;
float preyEnergyDecay = 0.15;       // 毎フレーム減少するエネルギー
float preyReproduceRate = 0.003;    // 繁殖確率（毎フレーム）
float preyReproduceEnergyCost = 30; // 繁殖時のエネルギーコスト
float preyMinReproduceEnergy = 60;  // 繁殖に必要な最低エネルギー

// Predator（捕食者/肉食）のパラメータ
float predatorMaxSpeed = 3.0;
float predatorSize = 10;
float predatorInitialEnergy = 150;
float predatorEnergyDecay = 0.3;      // 毎フレーム減少するエネルギー
float predatorEnergyGain = 80;        // Preyを食べた時に得るエネルギー
float predatorReproduceRate = 0.01;   // 繁殖確率（条件を満たした時）
float predatorReproduceEnergyCost = 60; // 繁殖時のエネルギーコスト
float predatorMinReproduceEnergy = 120; // 繁殖に必要な最低エネルギー

// 接触判定距離
float eatDistance = 10;

// ================================================================
// グローバル変数
// ================================================================
ArrayList<Prey> preys;
ArrayList<Predator> predators;

void setup() {
  size(800, 600);
  
  // Preyを初期化
  preys = new ArrayList<Prey>();
  for (int i = 0; i < initialPreyCount; i++) {
    preys.add(new Prey(random(width), random(height)));
  }
  
  // Predatorを初期化
  predators = new ArrayList<Predator>();
  for (int i = 0; i < initialPredatorCount; i++) {
    predators.add(new Predator(random(width), random(height)));
  }
}

void draw() {
  background(0);
  
  // Preyの更新・描画
  for (int i = preys.size() - 1; i >= 0; i--) {
    Prey prey = preys.get(i);
    prey.update();
    prey.display();
    
    // エネルギーが0以下なら死亡
    if (prey.energy <= 0) {
      preys.remove(i);
      continue;
    }
    
    // 繁殖チェック
    if (prey.energy > preyMinReproduceEnergy && random(1) < preyReproduceRate) {
      prey.energy -= preyReproduceEnergyCost;
      preys.add(new Prey(prey.x + random(-15, 15), prey.y + random(-15, 15)));
    }
  }
  
  // Predatorの更新・描画・捕食
  for (int i = predators.size() - 1; i >= 0; i--) {
    Predator predator = predators.get(i);
    predator.update();
    predator.display();
    
    // エネルギーが0以下なら死亡
    if (predator.energy <= 0) {
      predators.remove(i);
      continue;
    }
    
    // Preyとの接触判定（捕食）
    for (int j = preys.size() - 1; j >= 0; j--) {
      Prey prey = preys.get(j);
      float d = dist(predator.x, predator.y, prey.x, prey.y);
      if (d < eatDistance) {
        // Preyを食べる
        preys.remove(j);
        predator.energy += predatorEnergyGain;
      }
    }
    
    // 繁殖チェック（十分なエネルギーがある場合のみ）
    if (predator.energy > predatorMinReproduceEnergy && random(1) < predatorReproduceRate) {
      predator.energy -= predatorReproduceEnergyCost;
      predators.add(new Predator(predator.x + random(-15, 15), predator.y + random(-15, 15)));
    }
  }
  
  // 個体数情報を表示
  fill(255);
  textSize(14);
  text("Prey: " + preys.size(), 10, 25);
  text("Predators: " + predators.size(), 10, 45);
}

// ================================================================
// 基底クラス（共通機能）
// ================================================================
abstract class Creature {
  float x, y;
  float vx, vy;
  float noiseOffsetX, noiseOffsetY;
  float noiseScale = 0.005;
  float maxSpeed;
  float size;
  float energy;
  color c;
  
  Creature(float startX, float startY) {
    x = startX;
    y = startY;
    vx = 0;
    vy = 0;
    noiseOffsetX = random(1000);
    noiseOffsetY = random(1000);
  }
  
  void update() {
    // パーリンノイズで滑らかな移動
    float angleX = map(noise(noiseOffsetX), 0, 1, -1, 1);
    float angleY = map(noise(noiseOffsetY), 0, 1, -1, 1);
    
    vx += angleX * 0.1;
    vy += angleY * 0.1;
    
    // 速度制限
    float speed = sqrt(vx * vx + vy * vy);
    if (speed > maxSpeed) {
      vx = (vx / speed) * maxSpeed;
      vy = (vy / speed) * maxSpeed;
    }
    
    x += vx;
    y += vy;
    
    noiseOffsetX += noiseScale;
    noiseOffsetY += noiseScale;
    
    wrapAround();
  }
  
  void wrapAround() {
    if (x < 0) x = width;
    else if (x > width) x = 0;
    if (y < 0) y = height;
    else if (y > height) y = 0;
  }
  
  void display() {
    noStroke();
    fill(c);
    ellipse(x, y, size, size);
  }
}

// ================================================================
// Prey（被食者/草食）クラス
// ================================================================
class Prey extends Creature {
  Prey(float startX, float startY) {
    super(startX, startY);
    maxSpeed = preyMaxSpeed;
    size = preySize;
    energy = preyInitialEnergy;
    c = color(100, 255, 100); // 緑色
  }
  
  void update() {
    super.update();
    energy -= preyEnergyDecay;
  }
}

// ================================================================
// Predator（捕食者/肉食）クラス
// ================================================================
class Predator extends Creature {
  Predator(float startX, float startY) {
    super(startX, startY);
    maxSpeed = predatorMaxSpeed;
    size = predatorSize;
    energy = predatorInitialEnergy;
    c = color(255, 100, 100); // 赤色
  }
  
  void update() {
    super.update();
    energy -= predatorEnergyDecay;
  }
}
