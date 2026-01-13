# Evolving Ecosystem Simulation

A minimal, interactive ecosystem simulation built with [Processing](https://processing.org/). Inspired by Joan Soler-Adillon's aesthetic approach to creative coding.

![Preview](assets/preview.gif)

## Features

### 🧬 Evolution & Genetics

- Creatures inherit traits from parents with random mutations
- Evolved traits: **speed**, **sensor radius**, **size**
- Trade-offs: larger creatures are slower, faster creatures consume more energy

### 🐰 Prey Behavior (Flocking)

- **Separation**: Avoid crowding nearby flockmates
- **Alignment**: Steer towards average heading of neighbors
- **Cohesion**: Move toward the center of nearby flockmates
- **Flee**: Escape from approaching predators

### 🦊 Predator Behavior

- Hunt nearest prey within sensor range
- Consume prey on contact to gain energy
- Die when energy depletes

### 🛡️ Mobbing Defense

When **3+ prey** surround a predator, they collectively attack:

- Predator cannot hunt and loses energy rapidly
- Attacking prey glow yellow

### 📊 Population Graph

Real-time visualization of prey/predator population dynamics at the bottom of the screen.

### 🔍 Creature Inspector

Hover over any creature to see:

- Sensor radius visualization
- Target connection line
- Genetic parameters (speed, sensor, size, energy)

## Controls

| Key       | Action                   |
| --------- | ------------------------ |
| **Drag**  | Spawn prey at cursor     |
| **Space** | Spawn predator at cursor |
| **R**     | Reset simulation         |

## Parameters

All tuning parameters are collected at the top of `main.pde` for easy adjustment:

```java
// Initial population
int initialPreyCount = 100;
int initialPredatorCount = 8;

// Flocking weights
float separationWeight = 1.8;
float cohesionWeight = 1.5;
float fleeWeight = 2.0;

// Mobbing defense
float mobbingRadius = 50;
int minMobbingCount = 3;

// Evolution
float mutationRate = 0.15;
float mutationAmount = 0.1;
```

## Requirements

- [Processing 4.x](https://processing.org/download)

## Usage

1. Open `main/main.pde` in Processing
2. Click the **Run** button
3. Observe the ecosystem dynamics
4. Interact using mouse and keyboard

## License

MIT
