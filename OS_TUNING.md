# X99 OS-only Power & Longevity Tuning Guide
(For Xeon / X99 boards with limited BIOS tuning)

This document describes an **OS-level only tuning strategy**
for X99 motherboards (Huananzhi, Machinist, etc.) where BIOS options
are unreliable or too limited.

Target goals:
- ~30% average workload
- Stable power draw (no spikes)
- Low heat
- Maximum hardware longevity
- Long-term k3s / server operation

---

## Core Principles

1. Avoid CPU frequency and voltage spikes
2. Prefer stable, flat power usage
3. Use many cores at low frequency
4. Keep thermal behavior predictable
5. Enforce strict workload resource limits

OS-level tuning achieves ~80% of the benefits without touching BIOS.

---

## Target Operating Envelope

| Component | Target |
|---------|--------|
| CPU usage | ~30% average |
| CPU frequency | 60–70% of max |
| CPU temperature | 45–60°C |
| VRM temperature | < 70°C |
| Fan behavior | Fixed / steady |
| Power draw | Flat, no spikes |

---

## 1. CPU Power Management (Most Important)

### 1.1 Install required tools

```sh
sudo apt install -y linux-tools-common linux-tools-generic
```

---

### 1.2 Force CPU governor to powersave

```sh
sudo cpupower frequency-set -g powersave
```

Notes:
- `powersave` is NOT weak on many-core Xeons
- Prevents aggressive boosting
- Reduces VRM and PSU stress

---

### 1.3 Hard cap CPU frequency (critical step)

Example: cap max frequency at 2.2 GHz

```sh
sudo cpupower frequency-set -u 2200MHz
```

Recommended ranges:
- 2.0 GHz → maximum efficiency
- 2.2 GHz → sweet spot
- 2.4 GHz → still safe

This single step dramatically reduces power spikes and heat.

---

### 1.4 (Optional) Disable unused CPU cores

Only if workload is very light.

```sh
echo 0 | sudo tee /sys/devices/system/cpu/cpu60/online
```

Fewer active cores = less leakage power.

---

## 2. Kernel & Memory Tuning (Avoid Hidden Spikes)

### 2.1 Reduce swap aggressiveness

```sh
sudo tee /etc/sysctl.d/99-longevity.conf <<EOF
vm.swappiness=10
EOF

sudo sysctl --system
```

---

### 2.2 Disable Transparent Huge Pages (Recommended)

```sh
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
```

THP causes:
- Latency jitter
- CPU bursts
- Sudden heat increase

Bad for long-term stability.

---

### 2.3 Smooth disk I/O behavior

```sh
sudo tee -a /etc/sysctl.d/99-longevity.conf <<EOF
vm.dirty_ratio=15
vm.dirty_background_ratio=5
EOF

sudo sysctl --system
```

---

## 3. Minimal Monitoring (Detect Aging Early)

Install sensors:

```sh
sudo apt install -y lm-sensors
sudo sensors-detect
```

Monitor:
- CPU temperature
- VRM temperature (if available)
- Trend over time

If temperature slowly rises at same workload → hardware aging sign.

---

## 4. Things You Should NOT Do

- Do NOT use `performance` governor
- Do NOT run long stress tests
- Do NOT allow 100% CPU usage continuously
- Do NOT run pods without limits
- Do NOT trust AUTO BIOS power settings on X99 boards

---

## Final Notes

For X99 systems with poor BIOS tuning support:

OS-level power control is the **correct and safest approach**.

With:
- powersave governor
- frequency cap
- ~30% workload
- steady cooling

The system can run **boring, stable, and efficient** for many years.

Boring is good.
