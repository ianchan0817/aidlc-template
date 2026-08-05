# Know Your Unknowns — elicitation moves

The map is not the territory — the gap is your unknowns. Four kinds: **known knowns**, **known unknowns** (identified gaps), **unknown knowns** (unstated assumptions), **unknown unknowns** (blindspots). Before any code is written is the cheapest place to find one.

Each move is a prompt pattern; phase files point here. Run one when its trigger matches. Plain markdown works everywhere; interactive mockups amplify these where your tool renders them.

## Before implementation
- **Blindspot pass** — unfamiliar code. "Find my unknown unknowns here, explain each, and tell me how to prompt around it." Landmines, conventions, missing concepts, each with file refs and mitigation; ends with one improved prompt folding in every discovery.
- **Teach me the vocabulary** — unfamiliar domain. "Teach me enough to prompt with the words a professional would use": mental model → term ladder → quality criteria.
- **Interview** — ambiguous requirements. Reverse the dynamic: "Interview me one question at a time, prioritising questions where my answer changes the architecture." Order by blast radius.
- **Intervention brainstorm** — many possible fixes. "Search the codebase and brainstorm places we could intervene, cheapest to most ambitious (S/M/L/XL)." Grounded in real code, not speculation.
- **Design directions** — can't articulate the design. Render 3–4 incompatible directions on the same data; react, then name what's worth stealing from the losers. Reaction beats imagination.
- **Mock before wiring** — layout or behavior uncertain. One mock, fake data, variants side by side, explicit scope boundary. You learn what you want the moment you can click it.
- **Reference semantics map** — porting behavior. Before a line is ported: side-by-side comparison, gotchas, preserved/changed/dropped table, edge cases, sign-off. Comprehension becomes a reviewable artifact.
- **Tweakable plan** — plan with judgment calls. Order by decision volatility, not build order: decisions first (recommendation, rejected alternative, reversal trigger), then sequencing, then mechanical work. Top-to-bottom = most worth attention first.

## During implementation
- **Implementation notes** — typed deviation log (`aidlc/examples/implementation-notes.md`). Surprises become fold-back bullets for the next plan instead of vanishing into scrollback.

## After implementation
- **Buy-in doc** — multi-stakeholder ship. Demo first, then pitch, pre-answered objections, risk & rollback, named sign-offs. The last unknown is other people.
- **Change quiz** — high-blast-radius merge. Mental model + non-obvious behaviors + scored questions. Turns "I skimmed the diff" into verified understanding.
