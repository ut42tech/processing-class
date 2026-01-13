// 進化する生態系シミュレーション
// 「観測と介入」- 神の視点ツール
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
float mobbingEnergyDrain = 3.5;

// 進化パラメータ
float mutationRate = 0.15;
float mutationAmount = 0.1;

// ビジュアル設定
color bgColor = color(20, 20, 25);
color preyBaseColor = color(0, 210, 200);
color predatorBaseColor = color(255, 50, 130);
color mobbingColor = color(255, 255, 150);
int creatureAlpha = 200;
float bgFadeAlpha = 25;

// グラフ設定
float graphHeightRatio = 0.18;
int graphMaxHistory = 400;
color graphBgColor = color(10, 10, 15, 200);

// マウス操作
int spawnRate = 2;

// ================================================================
// グローバル変数
// ================================================================
ArrayList<Prey> preys;
ArrayList<Predator> predators;
int generation = 0;

// グラフ用履歴データ
ArrayList<Integer> preyHistory;
ArrayList<Integer> predatorHistory;

// モード切り替え
boolean debugMode = false;
Creature hoveredCreature = null;

// シミュレーション領域
int simHeight;
int graphHeight;

void setup() {
  size(1000, 800);
  noStroke();
  rectMode(CENTER);
  textFont(createFont("Monospaced", 10));
  
  graphHeight = int(height * graphHeightRatio);
  simHeight = height - graphHeight;
  
  preyHistory = new ArrayList<Integer>();
  predatorHistory = new ArrayList<Integer>();
  
  initSimulation();
}

void initSimulation() {
  background(bgColor);
  generation = 0;
  preyHistory.clear();
  predatorHistory.clear();
  
  preys = new ArrayList<Prey>();
  for (int i = 0; i < initialPreyCount; i++) {
    preys.add(new Prey(random(width), random(simHeight), null));
  }
  
  predators = new ArrayList<Predator>();
  for (int i = 0; i < initialPredatorCount; i++) {
    predators.add(new Predator(random(width), random(simHeight), null));
  }
}

void draw() {
  // シミュレーション領域の背景
  fill(bgColor, bgFadeAlpha);
  noStroke();
  rect(width/2, simHeight/2, width, simHeight);
  
  // ホバー検出リセット
  hoveredCreature = null;
  float closestDist = 30;
  
  // Mobbing状態をリセット
  for (Prey p : preys) {
    p.isMobbing = false;
  }
  
  // Predatorの更新
  for (int i = predators.size() - 1; i >= 0; i--) {
    Predator predator = predators.get(i);
    
    // ホバー検出
    float d = dist(mouseX, mouseY, predator.pos.x, predator.pos.y);
    if (d < closestDist && mouseY < simHeight) {
      closestDist = d;
      hoveredCreature = predator;
    }
    
    // Mobbing判定
    int nearbyPreyCount = 0;
    ArrayList<Prey> nearbyPreys = new ArrayList<Prey>();
    for (Prey prey : preys) {
      float pd = PVector.dist(predator.pos, prey.pos);
      if (pd < mobbingRadius) {
        nearbyPreyCount++;
        nearbyPreys.add(prey);
      }
    }
    
    predator.isBeingMobbed = nearbyPreyCount >= minMobbingCount;
    
    if (predator.isBeingMobbed) {
      predator.energy -= mobbingEnergyDrain;
      for (Prey prey : nearbyPreys) {
        prey.isMobbing = true;
      }
    } else {
      for (int j = preys.size() - 1; j >= 0; j--) {
        Prey prey = preys.get(j);
        float pd = PVector.dist(predator.pos, prey.pos);
        if (pd < eatDistance + predator.size/2) {
          preys.remove(j);
          predator.energy += predatorEnergyGain;
        }
      }
    }
    
    predator.hunt(preys);
    predator.update();
    predator.display();
    
    if (predator.energy <= 0) {
      predators.remove(i);
      continue;
    }
    
    if (predator.energy > predatorMinReproduceEnergy && random(1) < predatorReproduceRate) {
      predator.energy -= predatorReproduceEnergyCost;
      predators.add(new Predator(predator.pos.x + random(-20, 20), predator.pos.y + random(-20, 20), predator));
      generation++;
    }
  }
  
  // Preyの更新
  for (int i = preys.size() - 1; i >= 0; i--) {
    Prey prey = preys.get(i);
    
    // ホバー検出
    float d = dist(mouseX, mouseY, prey.pos.x, prey.pos.y);
    if (d < closestDist && mouseY < simHeight) {
      closestDist = d;
      hoveredCreature = prey;
    }
    
    prey.flock(preys, predators);
    prey.update();
    prey.display();
    
    if (prey.energy <= 0) {
      preys.remove(i);
      continue;
    }
    
    if (prey.energy > preyMinReproduceEnergy && random(1) < preyReproduceRate) {
      prey.energy -= preyReproduceEnergyCost;
      preys.add(new Prey(prey.pos.x + random(-15, 15), prey.pos.y + random(-15, 15), prey));
      generation++;
    }
  }
  
  // インスペクター描画
  if (hoveredCreature != null) {
    drawInspector(hoveredCreature);
  }
  
  // 履歴データを記録
  if (frameCount % 2 == 0) {
    preyHistory.add(preys.size());
    predatorHistory.add(predators.size());
    if (preyHistory.size() > graphMaxHistory) {
      preyHistory.remove(0);
      predatorHistory.remove(0);
    }
  }
  
  // グラフ描画
  drawGraph();
  
  // UI表示
  displayUI();
}

void drawInspector(Creature c) {
  // 感知範囲を描画
  stroke(255, 80);
  strokeWeight(1);
  noFill();
  ellipse(c.pos.x, c.pos.y, c.sensorRadius * 2, c.sensorRadius * 2);
  
  // ターゲットへの線を描画
  if (c.target != null) {
    stroke(255, 200, 0, 150);
    strokeWeight(2);
    line(c.pos.x, c.pos.y, c.target.x, c.target.y);
  }
  
  // デバッグモード：フロッキング力を描画
  if (debugMode && c instanceof Prey) {
    Prey p = (Prey) c;
    // Separation (赤)
    stroke(255, 100, 100);
    strokeWeight(2);
    line(p.pos.x, p.pos.y, p.pos.x + p.lastSep.x * 20, p.pos.y + p.lastSep.y * 20);
    // Alignment (緑)
    stroke(100, 255, 100);
    line(p.pos.x, p.pos.y, p.pos.x + p.lastAli.x * 20, p.pos.y + p.lastAli.y * 20);
    // Cohesion (青)
    stroke(100, 100, 255);
    line(p.pos.x, p.pos.y, p.pos.x + p.lastCoh.x * 20, p.pos.y + p.lastCoh.y * 20);
  }
  
  noStroke();
  
  // パラメータ表示
  fill(255, 220);
  textSize(10);
  String type = (c instanceof Prey) ? "PREY" : "PRED";
  String info = String.format("%s | Spd:%.2f Sen:%.0f Siz:%.1f E:%.0f", 
    type, c.maxSpeed, c.sensorRadius, c.size, c.energy);
  
  float textX = c.pos.x + c.size + 8;
  float textY = c.pos.y - 5;
  
  // 画面端補正
  if (textX + 180 > width) textX = c.pos.x - 185;
  if (textY < 15) textY = c.pos.y + 15;
  
  // 背景ボックス
  fill(0, 180);
  rect(textX + 85, textY, 175, 16, 3);
  fill(255, 220);
  textAlign(LEFT, CENTER);
  text(info, textX + 3, textY);
  textAlign(LEFT, BASELINE);
}

void drawGraph() {
  // グラフ背景
  fill(graphBgColor);
  noStroke();
  rect(width/2, simHeight + graphHeight/2, width, graphHeight);
  
  // 境界線
  stroke(50);
  strokeWeight(1);
  line(0, simHeight, width, simHeight);
  
  if (preyHistory.size() < 2) return;
  
  // スケール計算
  int maxPop = 1;
  for (int i = 0; i < preyHistory.size(); i++) {
    maxPop = max(maxPop, preyHistory.get(i), predatorHistory.get(i));
  }
  maxPop = max(maxPop, 50);
  
  float graphY = simHeight + 15;
  float graphH = graphHeight - 30;
  float stepX = (float) width / graphMaxHistory;
  
  // Prey線（シアン）
  stroke(preyBaseColor);
  strokeWeight(1.5);
  noFill();
  beginShape();
  for (int i = 0; i < preyHistory.size(); i++) {
    float x = i * stepX;
    float y = map(preyHistory.get(i), 0, maxPop, graphY + graphH, graphY);
    vertex(x, y);
  }
  endShape();
  
  // Predator線（マゼンタ）
  stroke(predatorBaseColor);
  beginShape();
  for (int i = 0; i < predatorHistory.size(); i++) {
    float x = i * stepX;
    float y = map(predatorHistory.get(i), 0, maxPop, graphY + graphH, graphY);
    vertex(x, y);
  }
  endShape();
  
  // ラベル
  noStroke();
  fill(preyBaseColor);
  textSize(9);
  text("● PREY: " + preys.size(), 10, simHeight + 13);
  fill(predatorBaseColor);
  text("● PRED: " + predators.size(), 90, simHeight + 13);
  fill(100);
  text("Max: " + maxPop, width - 60, simHeight + 13);
}

void displayUI() {
  fill(255, 180);
  textSize(10);
  
  // 統計情報
  float avgPreySpeed = 0, avgPredatorSpeed = 0;
  for (Prey p : preys) avgPreySpeed += p.maxSpeed;
  for (Predator p : predators) avgPredatorSpeed += p.maxSpeed;
  if (preys.size() > 0) avgPreySpeed /= preys.size();
  if (predators.size() > 0) avgPredatorSpeed /= predators.size();
  
  String stats = String.format("GEN: %d | Prey avg spd: %.2f | Predator avg spd: %.2f | FPS: %.0f", 
    generation, avgPreySpeed, avgPredatorSpeed, frameRate);
  text(stats, 10, 15);
  
  // コントロール
  String controls = "[DRAG] Prey  [SPACE] Predator  [R] Reset";
  text(controls, 10, 30);
}

void mouseDragged() {
  if (mouseY < simHeight && frameCount % spawnRate == 0) {
    preys.add(new Prey(mouseX + random(-8, 8), mouseY + random(-8, 8), null));
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    initSimulation();
  }
  if (key == ' ' && mouseY < simHeight) {
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
  PVector target; // インスペクター用：ターゲット位置
  
  float noiseOffsetX, noiseOffsetY;
  float noiseScale = 0.003;
  
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
    target = null;
    noiseOffsetX = random(1000);
    noiseOffsetY = random(1000);
  }
  
  void applyForce(PVector force) {
    acc.add(force);
  }
  
  void update() {
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
    
    float speedCost = (maxSpeed / preyBaseMaxSpeed) * 0.5;
    float sizeCost = (size / preyBaseSize) * 0.3;
    energy -= energyDecayRate * (1 + speedCost + sizeCost);
  }
  
  void wrapAround() {
    if (pos.x < 0) pos.x = width;
    else if (pos.x > width) pos.x = 0;
    if (pos.y < 0) pos.y = simHeight;
    else if (pos.y > simHeight) pos.y = 0;
  }
  
  abstract void display();
  
  float mutate(float value, float min, float max) {
    if (random(1) < mutationRate) {
      float change = value * random(-mutationAmount, mutationAmount);
      return constrain(value + change, min, max);
    }
    return value;
  }
}

// ================================================================
// Prey（被食者）クラス
// ================================================================
class Prey extends Creature {
  boolean isMobbing = false;
  PVector lastSep, lastAli, lastCoh; // デバッグ用
  
  Prey(float x, float y, Prey parent) {
    super(x, y);
    lastSep = new PVector(0, 0);
    lastAli = new PVector(0, 0);
    lastCoh = new PVector(0, 0);
    
    if (parent != null) {
      maxSpeed = mutate(parent.maxSpeed, 1.5, 4.5);
      size = mutate(parent.size, 3, 10);
      sensorRadius = mutate(parent.sensorRadius, 30, 100);
    } else {
      maxSpeed = preyBaseMaxSpeed + random(-0.5, 0.5);
      size = preyBaseSize + random(-1, 1);
      sensorRadius = preyBaseSensorRadius + random(-10, 10);
    }
    
    energy = preyInitialEnergy;
    energyDecayRate = preyBaseEnergyDecay;
    baseColor = preyBaseColor;
    
    maxSpeed = maxSpeed * (preyBaseSize / size) * 0.8 + maxSpeed * 0.2;
  }
  
  void flock(ArrayList<Prey> others, ArrayList<Predator> predators) {
    PVector sep = separation(others);
    PVector ali = alignment(others);
    PVector coh = cohesion(others);
    PVector flee = flee(predators);
    
    // デバッグ用に保存
    lastSep = sep.copy();
    lastAli = ali.copy();
    lastCoh = coh.copy();
    
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
    Predator closest = null;
    float closestDist = sensorRadius * 1.5;
    
    for (Predator pred : predators) {
      float d = PVector.dist(pos, pred.pos);
      if (d < closestDist) {
        closestDist = d;
        closest = pred;
        PVector diff = PVector.sub(pos, pred.pos);
        diff.normalize();
        diff.div(d);
        steer.add(diff);
        count++;
      }
    }
    
    // ターゲット設定（逃走対象）
    if (closest != null) {
      target = closest.pos.copy();
    } else {
      target = null;
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
    
    // ホバー時ハイライト
    if (this == hoveredCreature) {
      fill(255, 255);
      rect(pos.x, pos.y, size + 4, size + 4);
    }
    
    fill(c, creatureAlpha);
    rect(pos.x, pos.y, size, size);
  }
}

// ================================================================
// Predator（捕食者）クラス
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
    
    // ターゲット設定（インスペクター用）
    if (closest != null) {
      target = closest.pos.copy();
    } else {
      target = null;
    }
    
    if (closest != null && !isBeingMobbed) {
      PVector desired = PVector.sub(closest.pos, pos);
      desired.normalize();
      desired.mult(maxSpeed);
      PVector steer = PVector.sub(desired, vel);
      steer.limit(0.4);
      applyForce(steer);
    } else if (isBeingMobbed) {
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
    
    if (isBeingMobbed) {
      c = lerpColor(c, color(100, 50, 50), 0.5);
    }
    
    // ホバー時ハイライト
    if (this == hoveredCreature) {
      fill(255, 255);
      rect(pos.x, pos.y, size + 4, size + 4);
    }
    
    fill(c, creatureAlpha);
    rect(pos.x, pos.y, size, size);
  }
}
