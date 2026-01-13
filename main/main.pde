// 進化する生態系シミュレーション
// 「群れの力」と「進化の淘汰」
// Joan Soler-Adillonスタイルのミニマルデザイン

// ================================================================
// 調整用パラメータ（バランス調整用）
// ================================================================

// 初期個体数
int initialPreyCount = 100;
int initialPredatorCount = 8;

// Prey（被食者）基本パラメータ
float preyBaseMaxSpeed = 3.0;
float preyBaseSize = 5;
float preyBaseSensorRadius = 50;
float preyInitialEnergy = 100;
float preyBaseEnergyDecay = 0.12;
float preyReproduceRate = 0.004;
float preyReproduceEnergyCost = 30;
float preyMinReproduceEnergy = 55;

// Predator（捕食者）基本パラメータ
float predatorBaseMaxSpeed = 2.8;
float predatorBaseSize = 12;
float predatorBaseSensorRadius = 80;
float predatorInitialEnergy = 180;
float predatorBaseEnergyDecay = 0.35;
float predatorEnergyGain = 50;
float predatorReproduceRate = 0.008;
float predatorReproduceEnergyCost = 70;
float predatorMinReproduceEnergy = 140;

// 接触判定
float eatDistance = 12;

// フロッキング力の重み（Prey用）
float separationWeight = 1.8;
float alignmentWeight = 1.0;
float cohesionWeight = 1.5;
float fleeWeight = 2.0;
float flockingRadius = 45;

// 集団防衛（Mobbing）パラメータ
float mobbingRadius = 50;
int minMobbingCount = 3;
float mobbingEnergyDrain = 3.5;  // Predatorが受けるダメージ

// 進化パラメータ
float mutationRate = 0.15;  // 突然変異の確率
float mutationAmount = 0.1; // 変異の幅（パラメータの±10%）

// ビジュアル設定
color bgColor = color(20, 20, 25);
color preyBaseColor = color(0, 210, 200);    // シアン
color predatorBaseColor = color(255, 50, 130); // マゼンタ
color mobbingColor = color(255, 255, 150);   // 集団防衛時のハイライト
int creatureAlpha = 200;
float bgFadeAlpha = 25;

// マウス操作
int spawnRate = 2;

// ================================================================
// グローバル変数
// ================================================================
ArrayList<Prey> preys;
ArrayList<Predator> predators;
int generation = 0;

void setup() {
  size(1000, 700);
  noStroke();
  rectMode(CENTER);
  initSimulation();
}

void initSimulation() {
  background(bgColor);
  generation = 0;
  
  preys = new ArrayList<Prey>();
  for (int i = 0; i < initialPreyCount; i++) {
    preys.add(new Prey(random(width), random(height), null));
  }
  
  predators = new ArrayList<Predator>();
  for (int i = 0; i < initialPredatorCount; i++) {
    predators.add(new Predator(random(width), random(height), null));
  }
}

void draw() {
  // 軌跡を残す半透明背景
  fill(bgColor, bgFadeAlpha);
  rect(width/2, height/2, width, height);
  
  // Mobbing状態をリセット
  for (Prey p : preys) {
    p.isMobbing = false;
  }
  
  // Predatorの更新（先にMobbing判定のため）
  for (int i = predators.size() - 1; i >= 0; i--) {
    Predator predator = predators.get(i);
    
    // Mobbing判定：周囲のPrey数をカウント
    int nearbyPreyCount = 0;
    ArrayList<Prey> nearbyPreys = new ArrayList<Prey>();
    for (Prey prey : preys) {
      float d = PVector.dist(predator.pos, prey.pos);
      if (d < mobbingRadius) {
        nearbyPreyCount++;
        nearbyPreys.add(prey);
      }
    }
    
    predator.isBeingMobbed = nearbyPreyCount >= minMobbingCount;
    
    if (predator.isBeingMobbed) {
      // 集団防衛中：Predatorがダメージを受ける
      predator.energy -= mobbingEnergyDrain;
      // 攻撃中のPreyをハイライト
      for (Prey prey : nearbyPreys) {
        prey.isMobbing = true;
      }
    } else {
      // 通常の捕食
      for (int j = preys.size() - 1; j >= 0; j--) {
        Prey prey = preys.get(j);
        float d = PVector.dist(predator.pos, prey.pos);
        if (d < eatDistance + predator.size/2) {
          preys.remove(j);
          predator.energy += predatorEnergyGain;
        }
      }
    }
    
    // 追跡行動：最も近いPreyを追う
    predator.hunt(preys);
    predator.update();
    predator.display();
    
    if (predator.energy <= 0) {
      predators.remove(i);
      continue;
    }
    
    // 繁殖
    if (predator.energy > predatorMinReproduceEnergy && random(1) < predatorReproduceRate) {
      predator.energy -= predatorReproduceEnergyCost;
      predators.add(new Predator(predator.pos.x + random(-20, 20), predator.pos.y + random(-20, 20), predator));
      generation++;
    }
  }
  
  // Preyの更新
  for (int i = preys.size() - 1; i >= 0; i--) {
    Prey prey = preys.get(i);
    
    // フロッキング行動を適用
    prey.flock(preys, predators);
    prey.update();
    prey.display();
    
    if (prey.energy <= 0) {
      preys.remove(i);
      continue;
    }
    
    // 繁殖
    if (prey.energy > preyMinReproduceEnergy && random(1) < preyReproduceRate) {
      prey.energy -= preyReproduceEnergyCost;
      preys.add(new Prey(prey.pos.x + random(-15, 15), prey.pos.y + random(-15, 15), prey));
      generation++;
    }
  }
  
  // UI表示
  displayUI();
}

void displayUI() {
  fill(255, 200);
  textSize(11);
  
  // 統計情報
  float avgPreySpeed = 0, avgPredatorSpeed = 0;
  for (Prey p : preys) avgPreySpeed += p.maxSpeed;
  for (Predator p : predators) avgPredatorSpeed += p.maxSpeed;
  if (preys.size() > 0) avgPreySpeed /= preys.size();
  if (predators.size() > 0) avgPredatorSpeed /= predators.size();
  
  String stats = String.format("PREY: %d (avg spd: %.2f)  |  PREDATOR: %d (avg spd: %.2f)  |  GEN: %d", 
    preys.size(), avgPreySpeed, predators.size(), avgPredatorSpeed, generation);
  text(stats, 10, 20);
  text("[DRAG] add prey  |  [R] reset  |  [SPACE] add predator", 10, height - 12);
}

void mouseDragged() {
  if (frameCount % spawnRate == 0) {
    preys.add(new Prey(mouseX + random(-8, 8), mouseY + random(-8, 8), null));
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    initSimulation();
  }
  if (key == ' ') {
    predators.add(new Predator(mouseX, mouseY, null));
  }
}

// ================================================================
// 基底クラス（共通機能）- PVector使用
// ================================================================
abstract class Creature {
  PVector pos;
  PVector vel;
  PVector acc;
  
  float noiseOffsetX, noiseOffsetY;
  float noiseScale = 0.003;
  
  // 進化する形質（遺伝子）
  float maxSpeed;
  float size;
  float sensorRadius;
  
  float energy;
  float energyDecayRate;
  color baseColor;
  
  Creature(float x, float y) {
    pos = new PVector(x, y);
    vel = PVector.random2D();
    vel.mult(random(0.5, 1.5));
    acc = new PVector(0, 0);
    noiseOffsetX = random(1000);
    noiseOffsetY = random(1000);
  }
  
  void applyForce(PVector force) {
    acc.add(force);
  }
  
  void update() {
    // ランダムな揺らぎ（パーリンノイズ）
    float noiseX = map(noise(noiseOffsetX), 0, 1, -0.3, 0.3);
    float noiseY = map(noise(noiseOffsetY), 0, 1, -0.3, 0.3);
    applyForce(new PVector(noiseX, noiseY));
    
    vel.add(acc);
    vel.limit(maxSpeed);
    pos.add(vel);
    acc.mult(0);
    
    noiseOffsetX += noiseScale;
    noiseOffsetY += noiseScale;
    
    wrapAround();
    
    // エネルギー消費（速度とサイズに依存）
    float speedCost = (maxSpeed / preyBaseMaxSpeed) * 0.5;
    float sizeCost = (size / preyBaseSize) * 0.3;
    energy -= energyDecayRate * (1 + speedCost + sizeCost);
  }
  
  void wrapAround() {
    if (pos.x < 0) pos.x = width;
    else if (pos.x > width) pos.x = 0;
    if (pos.y < 0) pos.y = height;
    else if (pos.y > height) pos.y = 0;
  }
  
  abstract void display();
  
  // 遺伝子の突然変異
  float mutate(float value, float min, float max) {
    if (random(1) < mutationRate) {
      float change = value * random(-mutationAmount, mutationAmount);
      return constrain(value + change, min, max);
    }
    return value;
  }
}

// ================================================================
// Prey（被食者）クラス - フロッキング行動
// ================================================================
class Prey extends Creature {
  boolean isMobbing = false;
  
  Prey(float x, float y, Prey parent) {
    super(x, y);
    
    if (parent != null) {
      // 親から遺伝子を継承 + 突然変異
      maxSpeed = mutate(parent.maxSpeed, 1.5, 4.5);
      size = mutate(parent.size, 3, 10);
      sensorRadius = mutate(parent.sensorRadius, 30, 100);
    } else {
      // 初期個体
      maxSpeed = preyBaseMaxSpeed + random(-0.5, 0.5);
      size = preyBaseSize + random(-1, 1);
      sensorRadius = preyBaseSensorRadius + random(-10, 10);
    }
    
    energy = preyInitialEnergy;
    energyDecayRate = preyBaseEnergyDecay;
    baseColor = preyBaseColor;
    
    // トレードオフ：大きいと遅くなる
    maxSpeed = maxSpeed * (preyBaseSize / size) * 0.8 + maxSpeed * 0.2;
  }
  
  void flock(ArrayList<Prey> others, ArrayList<Predator> predators) {
    PVector sep = separation(others);
    PVector ali = alignment(others);
    PVector coh = cohesion(others);
    PVector flee = flee(predators);
    
    sep.mult(separationWeight);
    ali.mult(alignmentWeight);
    coh.mult(cohesionWeight);
    flee.mult(fleeWeight);
    
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    applyForce(flee);
  }
  
  PVector separation(ArrayList<Prey> others) {
    PVector steer = new PVector(0, 0);
    int count = 0;
    float desiredSep = size * 3;
    
    for (Prey other : others) {
      float d = PVector.dist(pos, other.pos);
      if (d > 0 && d < desiredSep) {
        PVector diff = PVector.sub(pos, other.pos);
        diff.normalize();
        diff.div(d);
        steer.add(diff);
        count++;
      }
    }
    if (count > 0) {
      steer.div(count);
      steer.normalize();
      steer.mult(maxSpeed);
      steer.sub(vel);
      steer.limit(0.3);
    }
    return steer;
  }
  
  PVector alignment(ArrayList<Prey> others) {
    PVector sum = new PVector(0, 0);
    int count = 0;
    
    for (Prey other : others) {
      float d = PVector.dist(pos, other.pos);
      if (d > 0 && d < sensorRadius) {
        sum.add(other.vel);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      sum.normalize();
      sum.mult(maxSpeed);
      PVector steer = PVector.sub(sum, vel);
      steer.limit(0.2);
      return steer;
    }
    return new PVector(0, 0);
  }
  
  PVector cohesion(ArrayList<Prey> others) {
    PVector sum = new PVector(0, 0);
    int count = 0;
    
    for (Prey other : others) {
      float d = PVector.dist(pos, other.pos);
      if (d > 0 && d < sensorRadius) {
        sum.add(other.pos);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);
    }
    return new PVector(0, 0);
  }
  
  PVector flee(ArrayList<Predator> predators) {
    PVector steer = new PVector(0, 0);
    int count = 0;
    
    for (Predator pred : predators) {
      float d = PVector.dist(pos, pred.pos);
      if (d < sensorRadius * 1.5) {
        PVector diff = PVector.sub(pos, pred.pos);
        diff.normalize();
        diff.div(d);
        steer.add(diff);
        count++;
      }
    }
    if (count > 0) {
      steer.div(count);
      steer.normalize();
      steer.mult(maxSpeed);
      steer.sub(vel);
      steer.limit(0.5);
    }
    return steer;
  }
  
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, pos);
    desired.normalize();
    desired.mult(maxSpeed);
    PVector steer = PVector.sub(desired, vel);
    steer.limit(0.15);
    return steer;
  }
  
  void display() {
    // 色を形質によって変化させる
    float speedRatio = map(maxSpeed, 1.5, 4.5, 0.7, 1.3);
    float sizeRatio = map(size, 3, 10, 0.8, 1.2);
    
    color c;
    if (isMobbing) {
      c = mobbingColor;
    } else {
      float r = red(baseColor) * speedRatio;
      float g = green(baseColor) * sizeRatio;
      float b = blue(baseColor);
      c = color(constrain(r, 0, 255), constrain(g, 0, 255), constrain(b, 0, 255));
    }
    
    fill(c, creatureAlpha);
    rect(pos.x, pos.y, size, size);
  }
}

// ================================================================
// Predator（捕食者）クラス - 狩猟行動
// ================================================================
class Predator extends Creature {
  boolean isBeingMobbed = false;
  
  Predator(float x, float y, Predator parent) {
    super(x, y);
    
    if (parent != null) {
      maxSpeed = mutate(parent.maxSpeed, 2.0, 5.0);
      size = mutate(parent.size, 8, 18);
      sensorRadius = mutate(parent.sensorRadius, 50, 150);
    } else {
      maxSpeed = predatorBaseMaxSpeed + random(-0.5, 0.5);
      size = predatorBaseSize + random(-2, 2);
      sensorRadius = predatorBaseSensorRadius + random(-15, 15);
    }
    
    energy = predatorInitialEnergy;
    energyDecayRate = predatorBaseEnergyDecay;
    baseColor = predatorBaseColor;
    
    // トレードオフ：大きいと遅くなる
    maxSpeed = maxSpeed * (predatorBaseSize / size) * 0.7 + maxSpeed * 0.3;
  }
  
  void hunt(ArrayList<Prey> preys) {
    Prey closest = null;
    float closestDist = sensorRadius;
    
    for (Prey prey : preys) {
      float d = PVector.dist(pos, prey.pos);
      if (d < closestDist) {
        closestDist = d;
        closest = prey;
      }
    }
    
    if (closest != null && !isBeingMobbed) {
      PVector desired = PVector.sub(closest.pos, pos);
      desired.normalize();
      desired.mult(maxSpeed);
      PVector steer = PVector.sub(desired, vel);
      steer.limit(0.4);
      applyForce(steer);
    } else if (isBeingMobbed) {
      // 集団攻撃を受けている場合は逃げる
      PVector flee = new PVector(0, 0);
      for (Prey prey : preys) {
        float d = PVector.dist(pos, prey.pos);
        if (d < mobbingRadius * 1.5) {
          PVector diff = PVector.sub(pos, prey.pos);
          diff.normalize();
          diff.div(d);
          flee.add(diff);
        }
      }
      flee.normalize();
      flee.mult(maxSpeed * 0.8);
      applyForce(flee);
    }
  }
  
  void display() {
    float speedRatio = map(maxSpeed, 2.0, 5.0, 0.8, 1.2);
    float sizeRatio = map(size, 8, 18, 0.9, 1.1);
    
    float r = red(baseColor) * sizeRatio;
    float g = green(baseColor) * speedRatio;
    float b = blue(baseColor);
    
    color c = color(constrain(r, 0, 255), constrain(g, 0, 255), constrain(b, 0, 255));
    
    // 集団攻撃を受けていたら暗くなる
    if (isBeingMobbed) {
      c = lerpColor(c, color(100, 50, 50), 0.5);
    }
    
    fill(c, creatureAlpha);
    rect(pos.x, pos.y, size, size);
  }
}
