#import "@preview/cetz:0.4.2"
#import "@preview/cetz-plot:0.1.2": plot

#set page(width: auto, height: auto, margin: 8pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)
#show math.equation: set text(font: "New Computer Modern Math")

// FSS-1000 test set, 37x37-grid-snapped action space, frozen-best params per family.
// All methods (heuristic, BC, RL) prompt SAM at 37x37 grid cell centers.
// Garnet is reserved for the headline trained method (RL fine-tune).
#let methods = (
  ("RL fine-tune (PPO, warm-start)",          rgb("#73000A"), "solid",  3.0pt, "triangle", ((5, 0.8643), (10, 0.8665))),
  ("BC v2 (DINO + masked + Gauss + IoU aux)", rgb("#466A9F"), "solid",  2.2pt, "square",   ((2, 0.6342), (5, 0.6717), (10, 0.5860))),
  ("Sim-weighted FPS (α=0.75)",               rgb("#A49137"), "solid",  2.0pt, "o",        ((1, 0.5852), (2, 0.6993), (3, 0.7409), (5, 0.7680), (7, 0.7561), (10, 0.7305))),
  ("Top-K + NMS (r=14)",                      rgb("#1F414D"), "solid",  1.6pt, "o",        ((1, 0.5852), (2, 0.6628), (3, 0.7167), (5, 0.7320), (7, 0.7321), (10, 0.7120))),
  ("Top-K → k-means (K'=256)",                rgb("#65780B"), "solid",  1.6pt, "o",        ((1, 0.5852), (2, 0.7021), (3, 0.7300), (5, 0.7179), (7, 0.6775), (10, 0.6283))),
  ("Local-maxima peaks (sep=6)",              rgb("#CED318"), "solid",  1.6pt, "o",        ((1, 0.5852), (2, 0.6786), (3, 0.7230), (5, 0.7318), (7, 0.6881), (10, 0.6311))),
  ("DPP (ℓ=18)",                              rgb("#676156"), "solid",  1.4pt, "o",        ((1, 0.5772), (2, 0.6569), (3, 0.6896), (5, 0.6814), (7, 0.6743), (10, 0.6487))),
  ("Connected-comp. centers (τ=0.75)",        rgb("#363636"), "solid",  1.4pt, "o",        ((1, 0.5852), (2, 0.6318), (3, 0.6527), (5, 0.6194), (7, 0.5933), (10, 0.5468))),
  ("Sim-weighted random (T=0.05)",            rgb("#A2A2A2"), "solid",  1.4pt, "o",        ((1, 0.4510), (2, 0.5892), (3, 0.6417), (5, 0.6456), (7, 0.6744), (10, 0.6681))),
  ("Mean-shift modes (bw=6)",                 rgb("#CC2E40"), "solid",  1.4pt, "o",        ((1, 0.6021), (2, 0.6420), (3, 0.6200), (5, 0.5560), (7, 0.5123), (10, 0.4602))),
  ("BC v1 (sim-map only)",                    rgb("#5C5C5C"), "dashed", 1.5pt, "square",   ((2, 0.6384), (5, 0.5295), (10, 0.4616))),
  ("Top-K argmax",                            rgb("#000000"), "solid",  2.0pt, "o",        ((1, 0.5852), (2, 0.5789), (3, 0.5714), (5, 0.5025), (7, 0.4449), (10, 0.3792))),
  ("Quantile-spaced",                         rgb("#C7C7C7"), "dashed", 1.2pt, "o",        ((1, 0.5852), (2, 0.1371), (3, 0.0923), (5, 0.0770), (7, 0.0768), (10, 0.0769))),
  ("Farthest Point Sampling",                 rgb("#C7C7C7"), "dashed", 1.2pt, "o",        ((1, 0.5852), (2, 0.1690), (3, 0.0624), (5, 0.0504), (7, 0.0430), (10, 0.0484))),
)

#cetz.canvas({
  import cetz.draw: *
  plot.plot(
    size: (12, 8.5),
    x-label: [N (point budget)],
    y-label: [mean IoU],
    x-min: 0.7, x-max: 10.5,
    y-min: 0, y-max: 0.92,
    x-tick-step: none,
    x-ticks: (1, 2, 3, 5, 7, 10),
    y-tick-step: 0.1,
    y-minor-tick-step: 0.05,
    x-grid: "major",
    y-grid: "major",
    legend: "east",
    legend-style: (
      stroke: none,
      fill: none,
      orientation: ttb,
      item: (spacing: 0.18),
    ),
    {
      for (label, color, dash, w, mark, pts) in methods {
        plot.add(
          pts,
          label: label,
          style: (stroke: (paint: color, thickness: w, dash: dash)),
          mark: mark,
          mark-size: if mark == "triangle" { 0.22 } else if mark == "square" { 0.16 } else { 0.13 },
          mark-style: (stroke: color, fill: color),
        )
      }
    },
  )
})
