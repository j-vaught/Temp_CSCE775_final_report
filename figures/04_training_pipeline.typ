// Figure 4 - BC warm start + PPO training pipeline. Laid out as a single
// horizontal main flow with the KL anchor branching off below the policy
// box. Loop arrow goes over the top.

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

  // ---- Layout knobs ---------------------------------------------------
  // Main row of boxes lives on this y-baseline; the KL anchor sits one
  // row below.
  let row-cy = 0
  let row-h  = 1.7
  // Per-edge gap before each box (gaps[0] is unused). Generous gap before
  // the PPO policy so the long "copy actor + backbone" label fits in it
  // without overflowing into the adjacent boxes.
  let gaps = (0.0, 3.6, 1.6, 1.6, 1.6)
  let y-b = row-cy - row-h / 2
  let y-t = row-cy + row-h / 2

  // Main-row boxes left-to-right. Lightened brand fills with black text so
  // the palette mirrors Figure 2.
  let mute = 85%
  // (width, fill, text-fill, header, body)
  let boxes = (
    (3.0, light10,                   black,
      [BC checkpoint],
      [$pi_("BC")$\ pretrained on oracle]),
    (3.6, garnet.lighten(mute),      black,
      [PPO policy $pi_theta$],
      [actor + backbone from BC,\ fresh value head]),
    (3.8, atlantic.lighten(mute),    black,
      [Rollout collection],
      [32 envs #sym.times $T$ steps\ ($T$ = 5 or 10)]),
    (3.4, congaree.lighten(mute),    black,
      [GAE advantages],
      [$gamma = 1.0,  lambda = 0.95$]),
    (4.0, horseshoe.lighten(mute),   black,
      [PPO update],
      [clip 0.2 #sym.dot 4 epochs #sym.dot mb 32\ LR + entropy: linear decay]),
  )

  // Edge labels between consecutive main-row boxes.
  let edge-labels = (
    [copy backbone],
    [act],
    none,
    none,
  )

  // ---- Walk main row, drawing each box and the arrow into it ---------
  let cur-x = 0
  let centers = ()       // (cx, cy) for each main-row box
  let edges-x = ()       // (x-l, x-r) for each box (used by anchor arrows)

  for (i, b) in boxes.enumerate() {
    let (w, fill-c, txt-c, header, body) = b
    let x-l = cur-x
    let x-r = cur-x + w
    let cx  = (x-l + x-r) / 2

    rect((x-l, y-b), (x-r, y-t), fill: fill-c,
      stroke: black + stroke-thin)
    content((cx, row-cy + 0.3),
      text(fill: txt-c, weight: "bold", size: fs-label)[#header])
    content((cx, row-cy - 0.3),
      align(center, text(fill: txt-c, size: fs-small)[#body]))

    centers.push((cx, row-cy))
    edges-x.push((x-l, x-r))

    // Forward arrow from previous box
    if i > 0 {
      let prev-x-r = cur-x - gaps.at(i)
      line((prev-x-r, row-cy), (x-l, row-cy),
        mark: (end: "stealth"))
      let label = edge-labels.at(i - 1)
      if label != none {
        content(((prev-x-r + x-l) / 2, row-cy + 0.5),
          box(fill: white, inset: (x: 3pt, y: 1pt),
            text(size: fs-small, weight: "bold")[#label]))
      }
    }

    // Advance past this box plus the gap before the NEXT box (if any)
    let next-gap = if i + 1 < boxes.len() { gaps.at(i + 1) } else { 0 }
    cur-x = x-r + next-gap
  }

  // ---- KL anchor block (below the PPO policy) ------------------------
  let policy-cx = centers.at(1).at(0)        // center x of PPO policy box
  let bc-x-r    = edges-x.at(0).at(1)        // right edge of BC checkpoint
  let upd-x-l   = edges-x.at(4).at(0)        // left edge of PPO update
  let upd-cx    = centers.at(4).at(0)        // center x of PPO update

  let kl-w   = 4.0
  let kl-h   = 1.4
  let kl-cy  = row-cy - 2.6
  let kl-cx  = policy-cx
  let kl-x-l = kl-cx - kl-w / 2
  let kl-x-r = kl-cx + kl-w / 2
  let kl-y-b = kl-cy - kl-h / 2
  let kl-y-t = kl-cy + kl-h / 2

  rect((kl-x-l, kl-y-b), (kl-x-r, kl-y-t),
    fill: garnet.lighten(85%), stroke: black + stroke-thin)
  content((kl-cx, kl-cy + 0.3),
    text(fill: black, weight: "bold", size: fs-label)[KL anchor])
  content((kl-cx, kl-cy - 0.05),
    text(fill: black, size: fs-small)[$beta_t #sym.dot "KL"(pi_theta || pi_("BC"))$])
  content((kl-cx, kl-cy - 0.35),
    text(size: fs-tiny, fill: black)[$beta$: 0.1 #sym.arrow 0.01])

  // PPO policy -> KL anchor (current pi_theta, vertical)
  line((policy-cx, y-b), (kl-cx, kl-y-t),
    mark: (end: "stealth"))
  // Label sits slightly above the vertical mid of the arrow but with
  // generous clearance below the PPO policy box.
  content((policy-cx + 0.5, y-b - 0.5),
    anchor: "west",
    box(fill: white, inset: (x: 3pt, y: 1pt),
      text(fill: black, size: fs-small, weight: "bold")[current $pi_theta$]))

  // BC checkpoint -> KL anchor (frozen reference, elbow down then right to
  // enter the KL box on its left side)
  let bc-cy = centers.at(0).at(1)
  let bc-cx = centers.at(0).at(0)
  line(
    (bc-cx, y-b),
    (bc-cx, kl-cy),
    (kl-x-l, kl-cy),
    mark: (end: "stealth", fill: black),
    stroke: black + stroke-normal,
  )
  content(((bc-cx + kl-x-l) / 2, kl-cy + 0.3),
    box(fill: white, inset: (x: 3pt, y: 1pt),
      text(size: fs-small, fill: black, weight: "bold")[frozen reference]))

  // KL anchor -> PPO update (regularizer, elbow right then up)
  line(
    (kl-x-r, kl-cy),
    (upd-cx, kl-cy),
    (upd-cx, y-b),
    mark: (end: "stealth", fill: black),
    stroke: black + stroke-normal,
  )
  content(((kl-x-r + upd-cx) / 2, kl-cy + 0.3),
    box(fill: white, inset: (x: 3pt, y: 1pt),
      text(size: fs-small, fill: black, weight: "bold")[regularizer]))

  // ---- Loop arrow: PPO update back to PPO policy, over the top -------
  let loop-y = y-t + 1.4
  line(
    (upd-cx, y-t),
    (upd-cx, loop-y),
    (policy-cx, loop-y),
    (policy-cx, y-t),
    mark: (end: "stealth"),
  )
  content(((policy-cx + upd-cx) / 2, loop-y + 0.3),
    box(fill: white, inset: (x: 3pt, y: 1pt),
      text(fill: black, size: fs-small, weight: "bold")[
        update $theta$  #h(2pt) #text(fill: black)[(repeat #sym.times 1,000,000 env steps)]
      ]))
})
