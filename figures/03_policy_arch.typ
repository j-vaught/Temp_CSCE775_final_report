// Figure 3 - CNN actor-critic policy network, drawn with neural-netz.
// Linear pipeline: 9-channel input -> 3 conv blocks -> Actor head -> 37x37
// logits. Value head branches off the backbone via an "air" skip and
// outputs the scalar V(s).

#import "@preview/neural-netz:0.3.0": draw-network
#import "style.typ": *

#set page(width: auto, height: auto, margin: 6mm)
#set text(font: "New Computer Modern", size: fs-label)
#show math.equation: set text(font: "New Computer Modern Math")


#v(2pt)

#align(center)[
  #draw-network(
    (
      // 9-channel observation tensor
      (
        type: "input",
        image: none,
        channels: ("9", "37"),
        widths: (0.35,),
        height: 7,
        depth: 7,
        label: "input",
        name: "in",
      ),

      // Shared conv backbone (spatial size 37x37 preserved throughout;
      // only channel count grows, shown by increasing width).
      (
        type: "conv",
        channels: ("32", "37"),
        widths: (0.45,),
        height: 6,
        depth: 6,
        label: "Conv 1",
        name: "c1",
        offset: 2,
      ),
      (
        type: "conv",
        channels: ("64", "37"),
        widths: (0.75,),
        height: 6,
        depth: 6,
        label: "Conv 2",
        name: "c2",
        offset: 1.4,
      ),
      (
        type: "conv",
        channels: ("128", "37"),
        widths: (1.05,),
        height: 6,
        depth: 6,
        label: "Conv 3",
        name: "c3",
        offset: 1.4,
      ),

      // Actor head: 1x1 conv producing the 37x37 logits volume.
      (
        type: "custom",
        widths: (0.5,),
        height: 5,
        depth: 5,
        label: "Actor head",
        fill: rgb("#73000A"),
        legend: "Actor head",
        name: "actor",
        offset: 2.4,
      ),

      // 37x37 logits as a flat 2D plane, drawn in the same thin-slab style
      // as the input block so it visually reads as a spatial map (not a
      // dense vector or a chunky square).
      (
        type: "custom",
        channels: ("1", "37"),
        width: 0.35,
        height: 4,
        depth: 4,
        fill: rgb("#B39DDB"),
        legend: "Output",
        label: "logits",
        name: "logits",
        offset: 1.8
      ),

      // Output node for the actor: a single sampled cell of the grid.
      // Tiny square because the action is one (x, y) coordinate.
      (
        type: "custom",
        width: 0.5,
        height: 0.5,
        depth: 0,
        fill: rgb("#B39DDB"),
        legend: "Output",
        label: "action",
        name: "action",
        offset: 1.8,
        show-connection: false,
      ),

      // Value head, placed after the action node in the layout but tied
      // to the backbone via an "air" skip connection below.
      (
        type: "custom",
        widths: (0.5,),
        height: 2.2,
        depth: 2.2,
        label: "Value head",
        fill: rgb("#1F414D"),
        legend: "Value head",
        name: "val",
        offset: 3.0,
      ),

      // Scalar value output: baseline V(s) used for PPO advantages.
      // Tiny square because V(s) is a single number, not a vector.
      (
        type: "custom",
        width: 0.5,
        height: 0.5,
        depth: 0,
        fill: rgb("#B39DDB"),
        legend: "Output",
        label: "V(s)\nbaseline",
        name: "vout",
        offset: 1.4,
      ),
    ),
    connections: (
      // Backbone -> value head, drawn as an arc beneath the actor pipeline.
      (
        from: "c3",
        to: "val",
        type: "skip",
        mode: "air",
        label: "shared features",
        pos: 5,
        touch-layer: true,
      ),
    ),
    palette: "warm",
    show-legend: false,
    scale: 90%,
  )
]

#v(6pt)

// Horizontal legend below the diagram. Each entry is a small color
// swatch + label; the colors mirror the fills used inside the network.
#let legend-swatch(color, label) = box(
  inset: 0pt,
  baseline: 1.5pt,
  stack(
    dir: ltr,
    spacing: 4pt,
    box(width: 10pt, height: 10pt, fill: color, stroke: black + 0.5pt),
    text(size: 9pt)[#label],
  ),
)

#align(center)[
  #stack(
    dir: ltr,
    spacing: 18pt,
    legend-swatch(rgb("#f7f1ed"), [Input]),
    legend-swatch(rgb("#ffe0a1"), [Convolution]),
    legend-swatch(rgb("#73000A"), [Actor head]),
    legend-swatch(rgb("#B39DDB"), [Output]),
    legend-swatch(rgb("#1F414D"), [Value head]),
  )
]

