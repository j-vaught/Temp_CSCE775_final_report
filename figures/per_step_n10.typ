#import "@preview/cetz:0.4.2"
#import "@preview/cetz-plot:0.1.2": plot

#set page(width: auto, height: auto, margin: 8pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)
#show math.equation: set text(font: "New Computer Modern Math")

// Per-step rollout IoU at N=10 on FSS-1000 test (450 episodes), unified 37x37 action space.
// RL N=10: artifacts/rl/runs/fss1000_rl_ppo_n10_warmstart_rerun_20260503/per_step_rollout_iou.csv
// BC v2 N=10: artifacts/greedy_bc/diagnostics/fss1000_greedy_bc_v2/budget_N10/per_step_rollout_iou_N10.csv
#let rl_n10 = (
  (1,  0.5543),
  (2,  0.7768),
  (3,  0.8312),
  (4,  0.8522),
  (5,  0.8634),
  (6,  0.8676),
  (7,  0.8661),
  (8,  0.8659),
  (9,  0.8692),
  (10, 0.8665),
)

#let bc_n10 = (
  (1,  0.5035),
  (2,  0.6162),
  (3,  0.6452),
  (4,  0.6332),
  (5,  0.6327),
  (6,  0.6203),
  (7,  0.6280),
  (8,  0.6085),
  (9,  0.5968),
  (10, 0.5860),
)

// Reference: best non-trained baseline at N=10 (sim-weighted FPS, α=0.75) under the unified 37x37-snapped action space.
#let baseline_n10 = 0.7305

#cetz.canvas({
  import cetz.draw: *
  plot.plot(
    size: (10, 6),
    x-label: [step (click index)],
    y-label: [mean IoU],
    x-min: 0.7, x-max: 10.5,
    y-min: 0.45, y-max: 0.92,
    x-tick-step: none,
    x-ticks: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    y-tick-step: 0.05,
    x-grid: "major",
    y-grid: "major",
    legend: "inner-south-east",
    legend-style: (
      stroke: none,
      fill: rgb("#FFFFFFEE"),
      orientation: ttb,
      item: (spacing: 0.10),
    ),
    {
      // Best non-trained baseline reference (sim-weighted FPS at N=10)
      plot.add(
        ((0.7, baseline_n10), (10.5, baseline_n10)),
        label: [Sim-weighted FPS],
        style: (stroke: (paint: rgb("#A49137"), thickness: 1.0pt, dash: "dashed")),
        mark: none,
      )
      // RL fine-tune at N=10
      plot.add(
        rl_n10,
        label: [RL PPO],
        style: (stroke: (paint: rgb("#73000A"), thickness: 1.5pt)),
        mark: "triangle",
        mark-size: 0.18,
        mark-style: (stroke: rgb("#73000A"), fill: rgb("#73000A")),
      )
      // BC v2 at N=10
      plot.add(
        bc_n10,
        label: [Behavioral Cloning],
        style: (stroke: (paint: rgb("#466A9F"), thickness: 1.5pt)),
        mark: "square",
        mark-size: 0.13,
        mark-style: (stroke: rgb("#466A9F"), fill: rgb("#466A9F")),
      )
    },
  )
})
