// Shared brand colors and styling for all RL diagrams.
// Brand palette is defined as plain rgb() values so any figure file
// can `#import "style.typ": *` and use them directly.

#let garnet     = rgb("#73000A")
#let black      = rgb("#000000")
#let white      = rgb("#FFFFFF")

#let dark90     = rgb("#363636")
#let dark70     = rgb("#5C5C5C")
#let mid50      = rgb("#A2A2A2")
#let light30    = rgb("#C7C7C7")
#let light10    = rgb("#ECECEC")
#let warmgrey   = rgb("#676156")
#let sandstorm  = rgb("#FFF2E3")

#let rose       = rgb("#CC2E40")
#let atlantic   = rgb("#466A9F")
#let congaree   = rgb("#1F414D")
#let horseshoe  = rgb("#65780B")
#let grass      = rgb("#CED318")
#let honeycomb  = rgb("#A49137")

// Common font sizes.
#let fs-title  = 12pt
#let fs-label  = 10pt
#let fs-small  = 8pt
#let fs-tiny   = 7pt

// Default stroke weight for square-cornered diagram boxes.
#let stroke-thin   = 0.8pt
#let stroke-normal = 1.2pt
#let stroke-bold   = 1.8pt
