// Figure 2 - State (stacked input planes) and the discrete 37x37 action space.

#import "@preview/cetz:0.4.2"
#import "style.typ": *

#set page(width: auto, height: auto, margin: 10pt)
#set text(font: "New Computer Modern", size: fs-label)
#show math.equation: set text(font: "New Computer Modern Math")
#cetz.canvas({
  import cetz.draw: *

  set-style(
    stroke: (paint: black, thickness: stroke-normal),
    content: (padding: 3pt),
    mark: (fill: black),
  )

  // Vertical anchor for both panel titles. They are emitted later, after
  // the variables they reference (bar-w, grid-cx) come into scope, so
  // each title auto-centers on the block it labels.
  let title-y = 7.3

  // ---- Left panel: channel list as labeled bars -----------------------
  // Each row is wide enough that the channel name sits INSIDE the colored
  // bar. Colors are muted (lightened brand colors) so black text reads
  // cleanly on every fill.
  let txt = black
  let mute = 85%
  let groups = (
    (
      "Query evidence",
      atlantic.lighten(mute), txt,
      ("DINO sim-map", "query DINO features"),
    ),
    (
      "Point / mask state",
      honeycomb.lighten(mute), txt,
      ("point-history mask", "current SAM mask"),
    ),
    (
      "Step counters",
      light30.lighten(70%), txt,
      ("step idx plane", "budget plane", "count plane"),
    ),
    (
      "Spatial priors",
      warmgrey.lighten(mute), txt,
      ("x-coord plane", "y-coord plane"),
    ),
  )

  let row-h = 0.55
  let bar-w = 3.6
  let gap-y = 0.18
  let group-gap = 0.4
  let x0 = 0.0

  // Title centered above the channel column
  content((x0 + bar-w / 2, title-y),
    text(weight: "bold", size: fs-title)[State $s_t$])

  // Collected y-centers of every channel bar so we can fan arrows out
  // of them after the loop.
  let bar-centers = ()

  let cur-y = 7.0
  for g in groups {
    let (g-name, g-color, txt-color, g-rows) = g
    let g-top = cur-y
    for name in g-rows {
      // wide colored bar with the channel name inside it
      rect(
        (x0, cur-y - row-h),
        (x0 + bar-w, cur-y),
        fill: g-color,
        stroke: black + stroke-thin,
      )
      content(
        (x0 + bar-w / 2, cur-y - row-h / 2),
        text(size: fs-small, fill: txt-color, weight: "bold")[#name],
      )
      bar-centers.push(cur-y - row-h / 2)
      cur-y = cur-y - row-h - gap-y
    }
    let g-bottom = cur-y + gap-y
    // brace-ish bracket on the far left of the group
    let bx = x0 - 0.18
    line((bx, g-top), (bx - 0.15, g-top), stroke: dark70 + 0.6pt)
    line((bx - 0.15, g-top), (bx - 0.15, g-bottom), stroke: dark70 + 0.6pt)
    line((bx - 0.15, g-bottom), (bx, g-bottom), stroke: dark70 + 0.6pt)
    // group name to the left of the bracket
    content(
      (bx - 0.25, (g-top + g-bottom) / 2),
      anchor: "east",
      text(size: fs-small, fill: black, weight: "bold")[#g-name],
    )
    cur-y = cur-y - group-gap + gap-y
  }

  // Caption below the channel list
  let stack-bottom = cur-y - 0.1
  content(
    (x0 + bar-w / 2, stack-bottom + 0.1),
    anchor: "north",
    text(size: fs-small, fill: black, weight: "bold")[
      9 channels, each 37 #sym.times 37
    ],
  )

  // ---- Middle: policy block (knobs: center + width + height) ----------
  let policy-cx = 8.2
  let policy-cy = 3.365
  let policy-w  = 2.8
  let policy-h  = 1.8
  // Derived edges (used by all arrows below; do not edit directly)
  let policy-x-l = policy-cx - policy-w / 2
  let policy-x-r = policy-cx + policy-w / 2
  let policy-y-b = policy-cy - policy-h / 2
  let policy-y-t = policy-cy + policy-h / 2
  let policy-y-c = policy-cy
  rect((policy-x-l, policy-y-b), (policy-x-r, policy-y-t),
    fill: garnet.lighten(85%), stroke: black + stroke-thin)
  content((policy-cx, policy-cy + 0.25),
    text(fill: black, weight: "bold", size: fs-label)[Policy $pi_theta$])
  content((policy-cx, policy-cy - 0.25),
    text(fill: black, size: fs-small)[CNN actor-critic])

  // ---- One elbow arrow per channel, distributed across policy's left edge
  // Each arrow: horizontal stub out of the bar, vertical bend at a shared
  // mid-x, then horizontal into a distinct point on the policy.
  let n-bars = bar-centers.len()
  let mid-x = (bar-w + policy-x-l) / 2
  let pad = 0.15
  let y-top = policy-y-t - pad
  let y-bot = policy-y-b + pad
  for (i, by) in bar-centers.enumerate() {
    let target-y = if n-bars == 1 { policy-y-c }
                   else { y-top - i * (y-top - y-bot) / (n-bars - 1) }
    line(
      (bar-w + 0.05, by),
      (mid-x, by),
      (mid-x, target-y),
      (policy-x-l, target-y),
      mark: (end: "stealth", fill: black),
      stroke: black + 0.8pt,
    )
  }

  // ---- Right panel: 37x37 action grid (knobs: center + cell size) -----
  let grid-cx   = 13.5
  let grid-cy   = 3.365
  let g-cols    = 12
  let g-rows    = 12
  let g-cell    = 0.35
  // Derived edges
  let grid-w     = g-cols * g-cell
  let grid-h     = g-rows * g-cell
  let grid-x-l   = grid-cx - grid-w / 2
  let grid-x-r   = grid-cx + grid-w / 2
  let grid-y-b   = grid-cy - grid-h / 2
  let grid-y-t   = grid-cy + grid-h / 2

  // Title centered above the action grid
  content((grid-cx, title-y),
    text(weight: "bold", size: fs-title)[Action $a_t$])

  // ---- Arrow from policy out to the action grid -----------------------
  // Routed: out of the policy's right edge, vertical to the grid's left-
  // edge midpoint, then in. Auto-reroutes if either block moves.
  line(
    (policy-x-r, policy-y-c),
    (grid-x-l, grid-cy),
    mark: (end: "stealth"),
    stroke: black + stroke-normal,
  )
  content(((grid-x-l - policy-x-r)/2 + policy-x-r, grid-cy + 0.2),
    box(fill: white, inset: (x: 3pt, y: 1pt),
      text(size: fs-small, fill: black, weight: "bold")[logits]))

  // ---- Grid cells -----------------------------------------------------
  let used = (
    (3, 8), (4, 8), (3, 7), (8, 4), (9, 4), (2, 2),
  )
  let chosen = (6, 6)
  for c in range(g-cols) {
    for r in range(g-rows) {
      let x0c = grid-x-l + c * g-cell
      let y0c = grid-y-t - r * g-cell
      let x1c = x0c + g-cell
      let y1c = y0c - g-cell
      let is-used = used.contains((c, r))
      let is-chosen = chosen == (c, r)
      let fill-c = if is-chosen { garnet }
                   else if is-used { mid50 }
                   else { sandstorm }
      rect((x0c, y1c), (x1c, y0c), fill: fill-c, stroke: dark70 + 0.4pt)
    }
  }

  // legend below grid
  let lg-y = grid-y-b - 0.4
  let lg-x = grid-x-l
  rect((lg-x, lg-y - 0.25), (lg-x + 0.35, lg-y), fill: garnet, stroke: black + 0.6pt)
  content((lg-x + 0.45, lg-y - 0.12), anchor: "west",
    text(size: fs-small)[chosen cell #sym.arrow positive point])
  rect((lg-x, lg-y - 0.65), (lg-x + 0.35, lg-y - 0.4), fill: mid50, stroke: black + 0.6pt)
  content((lg-x + 0.45, lg-y - 0.52), anchor: "west",
    text(size: fs-small)[already used (masked)])
  rect((lg-x, lg-y - 1.05), (lg-x + 0.35, lg-y - 0.8), fill: sandstorm, stroke: black + 0.6pt)
  content((lg-x + 0.45, lg-y - 0.92), anchor: "west",
    text(size: fs-small)[available])
})
