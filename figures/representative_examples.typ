#set page(width: auto, height: auto, margin: 6pt, fill: white)
#set text(size: 8pt, fill: black)
// Inherits Typst's default serif (Linux Libertine), matching charged-ieee body font.

#let base = "repr_examples/"

#let cell(query, method, n, iou) = box(
  width: 3.6cm,
  stack(
    spacing: 2pt,
    image(base + query + "/" + method + "_overlay.png", width: 100%),
    align(center, text(size: 7.5pt, [IoU = #iou])),
  ),
)

#let qcell(query) = box(
  width: 3.6cm,
  stack(
    spacing: 2pt,
    image(base + query + "/query.png", width: 100%),
    align(center, text(size: 7.5pt, [query])),
  ),
)

#let column-header(label) = align(center, text(weight: "bold", size: 9pt, label))
#let row-header(label) = align(center + horizon, box(width: 0.9cm, rotate(-90deg, reflow: true, text(size: 9pt, weight: "bold", label))))

#table(
  columns: (auto, auto, auto, auto, auto, auto),
  rows: (auto, auto, auto, auto),
  align: center + horizon,
  stroke: none,
  inset: 2.5pt,
  // header row
  [],
  column-header("Query"),
  column-header("Top-K argmax"),
  column-header("Sim-weighted FPS"),
  column-header("BC v2"),
  column-header("RL fine-tune"),
  // park bench
  row-header("Park Bench"),
    qcell("park_bench_s10_q2"),
    cell("park_bench_s10_q2", "topk_argmax_N10", 10, "0.00"),
    cell("park_bench_s10_q2", "sim_weighted_fps_N10", 10, "0.16"),
    cell("park_bench_s10_q2", "bc_v2_N10", 10, "0.21"),
    cell("park_bench_s10_q2", "rl_N10", 10, "*0.92*"),
  // coconut
  row-header("Coconut"),
    qcell("coconut_s1_q10"),
    cell("coconut_s1_q10", "topk_argmax_N10", 10, "0.41"),
    cell("coconut_s1_q10", "sim_weighted_fps_N10", 10, "0.87"),
    cell("coconut_s1_q10", "bc_v2_N10", 10, "0.41"),
    cell("coconut_s1_q10", "rl_N10", 10, "*0.96*"),
  // skateboard
  row-header("Skateboard"),
    qcell("skateboard_s10_q2"),
    cell("skateboard_s10_q2", "topk_argmax_N10", 10, "0.91"),
    cell("skateboard_s10_q2", "sim_weighted_fps_N10", 10, "*0.94*"),
    cell("skateboard_s10_q2", "bc_v2_N10", 10, "0.92"),
    cell("skateboard_s10_q2", "rl_N10", 10, "0.91"),
)
