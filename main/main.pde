// シンプル生態系シミュレーション
// Prey（被食者）とPredator（捕食者）の相互作用
// Joan Soler-Adillonスタイルのミニマルデザイン

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
float preyEnergyDecay = 0.15;
float preyReproduceRate = 0.003;
float preyReproduceEnergyCost = 30;
float preyMinReproduceEnergy = 60;

// Predator（捕食者/肉食）のパラメータ
float predatorMaxSpeed = 3.0;
float predatorSize = 10;
float predatorInitialEnergy = 150;
float predatorEnergyDecay = 0.3;
float predatorEnergyGain = 80;
float predatorReproduceRate = 0.01;
float predatorReproduceEnergyCost = 60;
float predatorMinReproduceEnergy = 120;

// 接触判定距離
float eatDistance = 10;

// ビジュアル設定
color bgColor = color(25, 25, 30);      // 濃いグレー背景
color preyColor = color(0, 230, 220);   // シアン（Prey）
color predatorColor = color(255, 60, 150); // マゼンタ（Predator）
int creatureAlpha = 180;                // 透明度
float bgFadeAlpha = 20;                 // 軌跡の残り具合（小さいほど長く残る）

// マウスでPrey生成
int spawnRate = 3; // ドラッグ中に何フレームごとに生成するか

// ================================================================
// グローバル変数
// ================================================================
ArrayList<Prey> preys;
ArrayList<Predator> predators;

void setup() {
  size(800, 600);
  noStroke();
  rectMode(CENTER);
  initSimulation();
}

void initSimulation() {
  background(bgColor);
  
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
  // 軌跡を残すための半透明背景
  fill(bgColor, bgFadeAlpha);
  rect(width/2, height/2, width, height);
  
  // Preyの更新・描画
  for (int i = preys.size() - 1; i >= 0; i--) {
    Prey prey = preys.get(i);
    prey.update();
    prey.display();
    
    if (prey.energy <= 0) {
      preys.remove(i);
      continue;
    }
    
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
    
    if (predator.energy <= 0) {
      predators.remove(i);
      continue;
    }
    
    for (int j = preys.size() - 1; j >= 0; j--) {
      Prey prey = preys.get(j);
      float d = dist(predator.x, predator.y, prey.x, prey.y);
      if (d < eatDistance) {
        preys.remove(j);
        predator.energy += predatorEnergyGain;
      }
    }
    
    if (predator.energy > predatorMinReproduceEnergy && random(1) < predatorReproduceRate) {
      predator.energy -= predatorReproduceEnergyCost;
      predators.add(new Predator(predator.x + random(-15, 15), predator.y + random(-15, 15)));
    }
  }
  
  // UI表示
  fill(255, 200);
  textSize(12);
  text("PREY: " + preys.size() + "  |  PREDATOR: " + predators.size(), 10, 20);
  text("[DRAG] add prey  |  [R] reset", 10, height - 15);
}

// マウスドラッグでPreyを生成
void mouseDragged() {
  if (frameCount % spawnRate == 0) {
    preys.add(new Prey(mouseX + random(-5, 5), mouseY + random(-5, 5)));
  }
}

// Rキーでリセット
void keyPressed() {
  if (key == 'r' || key == 'R') {
    initSimulation();
  }
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
    float angleX = map(noise(noiseOffsetX), 0, 1, -1, 1);
    float angleY = map(noise(noiseOffsetY), 0, 1, -1, 1);
    
    vx += angleX * 0.1;
    vy += angleY * 0.1;
    
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
    fill(c, creatureAlpha);
    rect(x, y, size, size);
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
    c = preyColor;
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
    c = predatorColor;
  }
  
  void update() {
    super.update();
    energy -= predatorEnergyDecay;
  }
}
