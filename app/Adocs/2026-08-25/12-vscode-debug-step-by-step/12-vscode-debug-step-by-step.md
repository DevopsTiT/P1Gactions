# VS Code Debug Step By Step

## Decision tree

```
code misbehaves / want to see why
  │
  ├─ folder opened? (File → Open Folder)
  │    no → open project folder first (single-file mode breaks many debug setups)
  │
  ├─ language extension installed?
  │    Python → "Python" + "Python Debugger" (or Pylance stack)
  │    JS/Node → built-in JS debugger usually enough
  │
  ├─ launch.json exists?
  │    no → Run and Debug → create a launch.json → pick language
  │
  ├─ set breakpoint (red dot in gutter) on a line that will run
  │
  ├─ start with F5 (or green play) — not plain Run without debug
  │
  ├─ hit pause?
  │    yes → Variables / Watch / Call Stack → Step Over / Into / Continue
  │    no  → wrong cwd? wrong file? code path never reached? attach vs launch?
  │
  └─ still lost? → Debug Console prints + confirm config "program" / "cwd" / "module"
```

```
breakpoint never hits
  → running with Debug (F5)?           not terminal `python app.py` alone
  → line actually executed?            dead code / wrong branch / wrong file
  → cwd correct?                       relative paths fail if cwd ≠ project root
  → launch vs attach?                  attach needs process already listening
  → extension active for language?
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What debugging is | Pause running code, inspect values, walk line by line |
| First requirement | Open a **folder** (project), not only one file |
| Config file | `.vscode/launch.json` tells the editor how to start under the debugger |
| Start command | F5 (or Run and Debug play) — not “run in terminal” alone |
| Main skills | Breakpoints, Continue, Step Over / Into / Out, Variables, Watch |
| Same in Cursor | Cursor is VS Code–based; same Debug UI and `launch.json` |

## Summary

Debugging means you **pause** your program on purpose, look at variables, and move forward one step at a time until you see the bug. In VS Code (and Cursor), you open a project folder, install the language tools, create `launch.json`, click a breakpoint, then press **F5**. Below is a beginner path for **Python** and **Node/JavaScript**.

## 1. What debugging is

| Idea | What it means | Why you care |
|------|---------------|--------------|
| Pause | Execution stops on a line you chose | You can look around before the bug “flies by” |
| Inspect | Read variable values and expressions | You verify what the code *actually* holds |
| Step | Move one line or one function call at a time | You follow the exact path the bug takes |
| vs print | `print` / `console.log` only dumps text | Debugger shows structure, stack, and history of calls |

Think of it like a video player: breakpoint = pause button; Step Over = next frame; Step Into = zoom into a scene.

## 2. Prerequisites

| Check | What to do | Why |
|-------|------------|-----|
| Open a folder | **File → Open Folder…** and pick the project root | Workspace root becomes default `cwd` and finds `.vscode/` |
| Not only a single file | Avoid editing one loose file with no folder | Extensions and `launch.json` often misbehave |
| Python tools | Install extensions: **Python** (and debugger support as prompted) | Without them, Python launch configs may fail |
| Node/JS tools | Built-in JavaScript debugger is usually enough | Optional: Node.js on PATH for `node` configs |
| Interpreter / runtime | Python: pick interpreter (bottom status bar). Node: `node -v` works in a terminal | Wrong interpreter = “runs but weird” or won’t start |

## 3. Create `.vscode/launch.json`

1. Open the **Run and Debug** view (left activity bar: play icon with a bug), or **View → Run**.
2. If there is no config yet, click **create a launch.json file** (or “create launch configuration”).
3. Pick your environment (e.g. **Python File** or **Node.js**).
4. VS Code creates `.vscode/launch.json` in the project folder.
5. You can edit names, `program`, `cwd`, `args`, and `env` later.

Minimal examples live next to this doc (copy into `.vscode/launch.json` or merge configs into one file’s `"configurations": [ ... ]` array):

- `12-vscode-debug-step-by-step-launch-python.json`
- `12-vscode-debug-step-by-step-launch-node.json`

## 4. Key UI (where to look)

| Panel / control | What it is | When you use it |
|-----------------|------------|-----------------|
| Run and Debug sidebar | Start configs, see sessions | Every debug session |
| Breakpoint (gutter) | Red dot left of line numbers | “Stop here when this line runs” |
| Variables | Locals / globals at the pause | See `x`, `user`, `req` values |
| Watch | Expressions you type once | Keep an eye on `len(items)` or `user.id` |
| Call Stack | Which functions called which | “How did I get here?” |
| Debug Console | Evaluate expressions while paused | Quick checks without editing code |
| Debug toolbar | Continue / Step / Restart / Stop | Control the paused run |

## 5A. Step-by-step — Python

| Step | Action |
|------|--------|
| 1 | **File → Open Folder** → your Python project |
| 2 | Install **Python** extension if prompted; select a Python interpreter |
| 3 | Create a small file, e.g. `app.py`, with a few lines and a function call |
| 4 | Run and Debug → **create a launch.json** → choose **Python File** (or paste the companion Python config) |
| 5 | Click left of a line number inside code that will run → red breakpoint |
| 6 | Press **F5** (or green play on the Python config) |
| 7 | When it pauses: open **Variables**; expand objects |
| 8 | Press **F10** (Step Over) a few times; try **F11** into a function |
| 9 | Use **Debug Console** to type an expression (e.g. `len(data)`) while paused |
| 10 | **Continue (F5)** until the next breakpoint, or **Stop** when done |

**Tiny sample you can paste into `app.py`:**

```python
def greet(name):
    message = f"hello, {name}"
    return message

def main():
    names = ["Ada", "Lin"]
    for n in names:
        print(greet(n))  # put a breakpoint on this line

if __name__ == "__main__":
    main()
```

## 5B. Step-by-step — Node / JavaScript

| Step | Action |
|------|--------|
| 1 | **File → Open Folder** → your JS project |
| 2 | Ensure Node is installed (`node` available in a terminal) |
| 3 | Create e.g. `index.js` with a small loop or function |
| 4 | Run and Debug → create launch.json → **Node.js** (or use companion Node config) |
| 5 | Set a breakpoint on a line inside the loop or function |
| 6 | Press **F5** |
| 7 | Inspect **Variables**; add a **Watch** like `i` or `user.name` |
| 8 | **F10** / **F11** / **Shift+F11** as needed |
| 9 | **Debug Console**: try `names.length` while paused |
| 10 | Stop when finished |

**Tiny sample for `index.js`:**

```javascript
function greet(name) {
  const message = `hello, ${name}`;
  return message;
}

function main() {
  const names = ["Ada", "Lin"];
  for (const n of names) {
    console.log(greet(n)); // breakpoint here
  }
}

main();
```

## 6. Controls (toolbar + keys)

| Control | Typical shortcut | What it does |
|---------|------------------|--------------|
| Continue / Start | F5 | Run until next breakpoint (or finish) |
| Step Over | F10 | Run current line; do **not** dive into called functions |
| Step Into | F11 | Enter the function called on this line |
| Step Out | Shift+F11 | Finish current function; stop in the caller |
| Restart | (toolbar) | Stop and start the same config again |
| Stop | Shift+F5 (often) | End the debug session |

**Rule of thumb for beginners:** use **Step Over (F10)** most of the time; use **Step Into (F11)** only when the bug is inside a function you wrote.

## 7. Breakpoints

| Type | How | What it means |
|------|-----|---------------|
| Normal | Click the gutter (left of line number) | Always pause when that line is about to run |
| Remove | Click the red dot again | No longer pauses there |
| Disable | Right-click breakpoint → Disable | Keep the mark, skip pausing for now |
| Conditional | Right-click gutter → **Add Conditional Breakpoint…** | Pause only if an expression is true (e.g. `i == 3` or `name == "Lin"`) |

Conditional breakpoints save time in loops: you skip hundreds of iterations and stop only on the interesting case.

## 8. Common mistakes

| Mistake | What you see | Fix |
|---------|--------------|-----|
| Wrong working directory (`cwd`) | FileNotFound, wrong config files, imports fail | Set `"cwd": "${workspaceFolder}"` in `launch.json` |
| Breakpoint never hits | Program runs to end with no pause | Confirm F5 debug start; line is executed; not optimized/skipped; correct file |
| Running without debug | No Variables panel, no pause | Use Run and Debug / F5, not only terminal run |
| Launch vs Attach | Attach fails or never connects | **Launch** starts the app for you; **Attach** connects to an already running process (needs port / process id) |
| Single file, no folder | Odd paths, no `.vscode` saved with project | Open Folder first |
| Wrong Python interpreter | Starts wrong env / missing packages | Click interpreter in status bar; match your venv |
| Breakpoint on blank / non-executable line | Dot appears but never stops | Put breakpoint on a real statement |

**Launch vs Attach (plain English):**

| Mode | Means | Beginner default |
|------|-------|------------------|
| Launch | Editor starts the program under the debugger | Yes — use this first |
| Attach | Program already running; debugger connects later | Advanced (servers, remote, special ports) |

## 9. Minimal `launch.json` shapes

Python (current file):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Current File",
      "type": "debugpy",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

Node (current file):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Node: Current File",
      "type": "node",
      "request": "launch",
      "program": "${file}",
      "cwd": "${workspaceFolder"},
      "console": "integratedTerminal"
    }
  ]
}
```

> Note: Older Python configs used `"type": "python"`. Newer setups often use `"type": "debugpy"`. If the UI wizard offers **Python File**, accept it — the generated type is fine.

## Data flow map

```
You (Open Folder)
  → Language extension ready
  → .vscode/launch.json (how to start)
  → Breakpoint in source
  → F5 Launch
       → Debugger starts process
       → Hits breakpoint → PAUSE
            → Variables / Watch / Call Stack / Debug Console
            → F10 / F11 / Shift+F11 / F5 Continue
       → End or Stop
```

```
Editor UI                    Runtime
---------                   -------
launch.json  ----------->  start python/node with debug hooks
breakpoint   ----------->  pause when line reached
Variables UI <-----------  memory / locals at pause
Step Over    ----------->  execute next statement
```

## Related files

| File | Role |
|------|------|
| `12-vscode-debug-step-by-step.md` | This guide |
| `12-vscode-debug-step-by-step-follow.txt` | Full chat-ready steps (EN + 中文) |
| `12-vscode-debug-step-by-step-launch-python.json` | Copy/merge into `.vscode/launch.json` for Python |
| `12-vscode-debug-step-by-step-launch-node.json` | Copy/merge into `.vscode/launch.json` for Node |
| `12.sh` | Optional one-liners (open paths; no auto-run required) |

## Commands

See [12.sh](./12.sh). These only help you open or inspect folders; debugging itself is UI-driven (F5, breakpoints).
