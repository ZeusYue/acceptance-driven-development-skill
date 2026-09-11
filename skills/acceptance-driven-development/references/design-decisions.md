# Design decisions

Use design work to resolve uncertainty that matters to the requested outcome. A clear specification can proceed directly to implementation. A request to explore or review a design produces a design deliverable until the user authorizes implementation.

Read relevant project facts before asking factual questions. Separate known constraints, inferred possibilities, and decisions that belong to the user. Group related questions when that makes the choice easier; ask incrementally when later choices depend on an earlier answer. Use candidate acceptance examples to expose ambiguity without presenting them as settled requirements.

Present a recommended approach and the meaningful trade-offs. Compare alternatives when they lead to materially different outcomes or costs; do not manufacture alternatives to fill a quota. Consider existing project patterns, standard and platform capabilities, installed dependencies, and new implementations according to fitness, reliability, and maintenance cost.

Give the user the decisions they need to make. Ordinary technical choices within the request remain the agent's responsibility. Obtain a decision before implementing a materially different product behavior, weakening an agreed guarantee, or taking consequences outside the current authorization. An authorization already present in the conversation remains effective. Preparation and independent work can continue while a dependent decision is pending.

For consequential changes, address the relevant failure modes: compatibility, state transitions, data integrity, migration and recovery, external contracts, and how verification will demonstrate the result. Scale the detail to the consequences, and arrange review before costly or irreversible action.

When decisions need to survive the conversation, record the goal, chosen approach and rationale, boundaries, unresolved decisions, and verification implications in the existing design or work document. Link to accepted criteria. A design document does not certify implementation or acceptance, and recording an agreed decision does not require another approval of the record itself.
