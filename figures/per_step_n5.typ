#import "@preview/cetz:0.4.2"
#import "@preview/cetz-plot:0.1.2": plot

#set page(width: auto, height: auto, margin: 8pt, fill: white)
#set text(font: "Helvetica", size: 9pt)

// Per-step rollout IoU at N=5 on FSS-1000 test (450 episodes).
// RL: artifacts/rl/runs/fss1000_rl_ppo_n5_warmstart/per_step_rollout_iou.csv
// BC: artifacts/greedy_bc/diagnostics/fss1000_greedy_bc_v2/budget_N5/per_step_rollout_iou.csv
#let rl_n5 = (
  (1, 0.5420),
  (2, 0.7863),
  (3, 0.8455),
  (4, 0.8597),
  (5, 0.8643),
)

#let bc_n5 = (
  (1, 0.4866),
  (2, 0.5988),
  (3, 0.6359),
  (4, 0.6530),
  (5, 0.6717),
)

// Reference: best non-trained baseline at N=5 (sim-weighted FPS, α=0.75) under the unified 37x37-snapped action space.
#let baseline_n5 = 0.7680

#cetz.canvas({
  import cetz.draw: *
  plot.plot(
    size: (10, 6),
    x-label: [step (click index)],
    y-label: [mean IoU],
    x-min: 0.7, x-max: 5.3,
    y-min: 0.40, y-max: 0.92,
    x-tick-step: none,
    x-ticks: (1, 2, 3, 4, 5),
    y-tick-step: 0.05,
    x-grid: "major",
    y-grid: "major",
    legend: "inner-south-east",
    legend-style: (
      stroke: none,
      fill: rgb("#FFFFFFEE"),
      orientation: ttb,
      item: (spacing: 0.18),
    ),
    {
      // Best non-trained baseline reference (sim-weighted FPS at N=5)
      plot.add(
        ((0.7, baseline_n5), (5.3, baseline_n5)),
        label: [Sim-weighted FPS at $N=5$ (best non-trained)],
        style: (stroke: (paint: rgb("#A49137"), thickness: 1.4pt, dash: "dashed")),
        mark: none,
      )
      // RL fine-tune
      plot.add(
        rl_n5,
        label: [RL fine-tune (PPO, warm-start)],
        style: (stroke: (paint: rgb("#73000A"), thickness: 3.0pt)),
        mark: "triangle",
        mark-size: 0.22,
        mark-style: (stroke: rgb("#73000A"), fill: rgb("#73000A")),
      )
      // BC v2
      plot.add(
        bc_n5,
        label: [BC v2 (DINO + masked + Gauss + IoU aux)],
        style: (stroke: (paint: rgb("#466A9F"), thickness: 2.2pt)),
        mark: "square",
        mark-size: 0.16,
        mark-style: (stroke: rgb("#466A9F"), fill: rgb("#466A9F")),
      )
    },
  )
})
