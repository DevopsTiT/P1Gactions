# YAML Structure Pic

```
file
 ├─ # comments
 ├─ metadata
 └─ workflow
     ├─ title, description, schemaVersion
     ├─ trigger (filterQuery, categories)
     └─ tasks
         └─ <task id>
             ├─ action: run-javascript
             ├─ position
             ├─ predecessors + conditions
             └─ input.script
                 ├─ imports
                 ├─ settings
                 ├─ helpers
                 └─ export default function → return result
```

```
OPEN lines:  1-37 comments | 38-70 frame | 72-296 task 1 | 298-685 task 2 | 687-863 task 3 | 865-956 task 4 | 958-1020 task 5
CLOSE lines: 1-20 comments | 22-55 frame | 57-187 task 1 | 189-291 task 2 | 293-343 task 3
```
