// Figure 1 - RL interaction loop, laid out as a single horizontal row
// with the return arrow looping over the top. Wide is fine, vertical
// height should stay tight.

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
  // Every box sits on the same horizontal row at this y-center, so the
  // forward arrows all run cleanly horizontal with no kinks.
  let row-cy = 0
  let row-h  = 1.7
  let gap    = 0.6
  let y-b = row-cy - row-h / 2
  let y-t = row-cy + row-h / 2

  // Box specs in left-to-right order.
  // (width, fill, text-fill, header content, body content)
  let boxes = (
    (2.4, sandstorm,            black,
      [State $s_t$],
      none),
    (3.6, garnet,               white,
      [Policy $pi_theta$],
      [CNN actor-critic\ 37 #sym.times 37 logits]),
    (3.0, atlantic,             white,
      [Action $a_t$],
      [one cell on grid]),
    (4.4, congaree,             white,
      [SAM Environment],
      [grid cell #sym.arrow pixel click\ re-run SAM, get new mask]),
    (3.4, horseshoe,            white,
      [Reward $r_t$],
      [$"IoU"_t - "IoU"_(t-1)$]),
    (2.4, light10,              black,
      [$s_(t+1)$],
      none),
  )

  // No per-arrow labels in this figure; the loop is self-explanatory.
  let edge-labels = ([], [], [], [], [])

  // ---- Walk the boxes left to right, drawing each + the arrow into it.
  let cur-x = 0
  let centers = ()      // (cx, cy) for each box
  let edges   = ()      // (x-right, x-left-of-next) so we can label arrows

  for (i, b) in boxes.enumerate() {
    let (w, fill-c, txt-c, header, body) = b
    let x-l = cur-x
    let x-r = cur-x + w
    let cx  = (x-l + x-r) / 2

    rect((x-l, y-b), (x-r, y-t), fill: fill-c,
      stroke: black + stroke-thin)

    // Header (always rendered)
    if body == none {
      content((cx, row-cy),
        text(fill: txt-c, weight: "bold", size: fs-title)[#header])
    } else {
      content((cx, row-cy + 0.3),
        text(fill: txt-c, weight: "bold", size: fs-label)[#header])
      content((cx, row-cy - 0.3),
        align(center, text(fill: txt-c, size: fs-small)[#body]))
    }

    centers.push((cx, row-cy))

    // Forward arrow into this box from the previous one
    if i > 0 {
      let prev-x-r = cur-x - gap
      line((prev-x-r, row-cy), (x-l, row-cy),
        mark: (end: "stealth"))
      // Edge label centered above the arrow
      let label = edge-labels.at(i - 1)
      if label != [] {
        content(((prev-x-r + x-l) / 2, row-cy + 0.45),
          box(fill: white, inset: (x: 3pt, y: 1pt),
            text(size: fs-small, weight: "bold")[#label]))
      }
    }

    cur-x = x-r + gap
  }

  // ---- Loop arrow from s_{t+1} back to State, routed over the top ----
  let last-cx = centers.last().at(0)
  let first-cx = centers.first().at(0)
  let loop-y = y-t + 1.4
  line(
    (last-cx, y-t),
    (last-cx, loop-y),
    (first-cx, loop-y),
    (first-cx, y-t),
    mark: (end: "stealth"),
  )
  content(((first-cx + last-cx) / 2, loop-y + 0.25),
    text(size: fs-small, weight: "bold")[loop])
 })
