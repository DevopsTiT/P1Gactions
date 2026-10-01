# Glossary

| Term | What it means |
|---|---|
| Event state "active" | Trigger fires when a problem opens (and on updates while open). |
| Event state "active or closed" | Also fires when the problem closes. Set by onProblemClose: true. |
| is_closed | v4 flag from prepare-close; true only for a closed problem. |
| Problems API status | OPEN or CLOSED, read live at run time. |
| event.status_transition | What changed in this event, e.g. CREATED, RESOLVED. |
