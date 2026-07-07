# Know Your Unknowns — elicitation moves

The map is not the territory — the gap between them is your unknowns. Four kinds: **known knowns** (understood), **known unknowns** (identified gaps), **unknown knowns** (unstated assumptions), **unknown unknowns** (blindspots). Before any code is written is the cheapest place to find one.

Each move below is a concrete prompt pattern. Phase files point here; run the move when its trigger matches. Plain markdown works everywhere; richer media (interactive mockups, clickable explainers) amplify the moves when your tool renders them.

## Before implementation

- **Blindspot pass** — entering unfamiliar code. "Find my unknown unknowns in this part of the codebase, explain each, and tell me how to prompt around each gap." Output: landmines, conventions, missing concepts — each with file refs, why it bites, and mitigation. Ends with one improved prompt folding in every discovery.
- **Teach me the vocabulary** — unfamiliar domain. "Teach me enough that I can prompt with the words a professional would use." Mental model → term ladder → quality criteria → sample professional-grade prompts.
- **Interview** — ambiguous requirements. Reverse the dynamic: "Interview me one question at a time about anything still ambiguous. Prioritize questions where my answer would change the architecture." Order by blast radius.
- **Intervention brainstorm** — problem with many possible fixes. "Search the codebase and brainstorm N places we could intervene, cheapest to most ambitious (S/M/L/XL). I'll say which resonate." Grounded in real code, not speculation.
- **Design directions** — human can't articulate the design. Render 3–4 incompatible directions on the same data; react, then name the details worth stealing from the losers. Reaction beats imagination.
- **Mock before wiring** — UI layout/behavior uncertain. Single mock with fake data, variants side by side, explicit scope boundary, targeted binary questions. You learn what you want the moment you can click it.
- **Reference semantics map** — porting existing behavior. Before a line is ported: side-by-side comparison, gotchas, preserved/changed/dropped table, edge-case matrix, sign-off gate. The agent proves comprehension as a reviewable artifact.
- **Tweakable plan** — plan with judgment calls. Order by decision volatility, not build order: decisions first (each with recommendation, rejected alternative, and a one-line reversal trigger), then sequencing, then mechanical work collapsed. Top-to-bottom = most worth attention first.

## During implementation

- **Implementation notes** — typed deviation log; format: `aidlc/examples/implementation-notes.md`. Surprises become fold-back bullets for the next plan instead of vanishing into scrollback.

## After implementation

- **Buy-in doc** — multi-stakeholder ship. Lead with the demo, pitch, pre-answered objections with spec refs, risk & rollback, named sign-offs. The last unknown is other people.
- **Change quiz** — high-blast-radius merge. Mental model + non-obvious behaviors + scored quiz. Turns "I skimmed the diff" into verified understanding; not done until you pass.
