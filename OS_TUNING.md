# X99 OS-only Power & Longevity Tuning (Persistent Version)
For Xeon / X99 motherboards with limited or unreliable BIOS tuning

This document provides a **fully persistent OS-level tuning strategy**
for X99 motherboards (Huananzhi, Machinist, etc.).

All runtime tunings (CPU governor, frequency cap, THP) are made
**persistent across reboots** using systemd.

---

## Target Goals

- ~30% average workload
- Flat and predictable power draw
- Low heat, no spikes
- Minimal VRM / PSU stress
- Long-term (5–8 years) stable operation
- Suitable for k3s and always-on servers

---

## Core Principles

1. Avoid CPU frequency and power spikes
2. Prefer stable, flat behavior over peak performance
3. Use many cores at low frequency
4. Eliminate bursty kernel behavior
5. Enforce strict workload limits

OS-level tuning provides ~80% of the benefit without touching BIOS.

---

## Target Operating Envelope

| Component | Target |
|---------|--------|
| CPU usage | ~30% average |
| CPU frequency | 2.0–2.4 GHz cap |
| CPU temperature | 45–60 °C |
| VRM temperature | < 70 °C |
| Fan behavior | Fixed / steady |
| Power draw | Flat, no spikes |

---

## 1. Install Required Tools

```sh
sudo apt update
sudo apt install -y \
  linux-tools-common \
  linux-tools-generic \
  lm-sensors
```

---

## 2. Kernel Memory Tuning (Persistent)

Create sysctl configuration:

```sh
sudo tee /etc/sysctl.d/99-x99-longevity.conf <<EOF
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
EOF
```

Apply immediately:

```sh
sudo sysctl --system
```

✔ These settings are **persistent across reboots**.

---

## 3. Disable Transparent Huge Pages (THP) – Persistent

THP causes CPU bursts, latency jitter, and heat spikes.
We disable both THP and THP defragmentation permanently.

This will be handled by a systemd service (see Section 5).

---

## 4. CPU Power Management (Runtime Settings)

The following settings **do NOT persist by default** and must be applied
at every boot:

- CPU governor = `powersave`
- CPU max frequency cap (example: 2.2 GHz)

These will be automated using systemd.

---

## 5. Create Persistent systemd Tuning Service (Critical Step)

Create a single service to enforce all runtime tunings at boot.

```sh
sudo tee /etc/systemd/system/x99-longevity-tuning.service <<'EOF'
[Unit]
Description=X99 OS-level Power & Longevity Tuning
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g powersave
ExecStart=/usr/bin/cpupower frequency-set -u 2200MHz
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start the service:

```sh
sudo systemctl daemon-reexec
sudo systemctl enable x99-longevity-tuning
sudo systemctl start x99-longevity-tuning
```

✔ After this step, **all tuning survives reboot**.

---

## 6. Optional: Disable Unused CPU Cores (Runtime Only)

Only if workload is very light.

```sh
echo 0 | sudo tee /sys/devices/system/cpu/cpu60/online
```

⚠️ This does NOT persist by default and is optional.
Use only if you know you have excess cores.

---

## 7. Cooling Strategy (Important for Longevity)

Due to weak X99 BIOS fan control:

- CPU fan: fixed 55–60%
- VRM fan: always on
- Case fans: constant speed, straight airflow

Rule:
Stable airflow > smart fan curves

---

## 8. Monitoring (Detect Hardware Aging Early)

Run sensor detection once:

```sh
sudo sensors-detect
```

Monitor regularly:
- CPU temperature
- VRM temperature (if available)
- Trend over time

If temperature increases at the same workload → aging or dust buildup.

---

## 9. Verify After Reboot

### CPU governor and frequency cap

```sh
cpupower frequency-info | grep "current policy"
```

Expected output includes:
- governor: powersave
- max frequency: 2.20 GHz

---

### Transparent Huge Pages

```sh
cat /sys/kernel/mm/transparent_hugepage/enabled
```

Expected:
```
always madvise [never]
```

---

## 10. What NOT To Do

- Do NOT use `performance` governor
- Do NOT run long stress tests
- Do NOT allow sustained 100% CPU usage
- Do NOT run pods without resource limits
- Do NOT trust AUTO BIOS power settings on X99 boards

---

## Final Notes

With:
- swap disabled
- sysctl tuning persistent
- CPU governor + frequency cap enforced at boot
- THP fully disabled
- ~30% workload
- steady cooling

An X99 Xeon system can run **boring, cool, and efficient** for many years.

Boring is good.
