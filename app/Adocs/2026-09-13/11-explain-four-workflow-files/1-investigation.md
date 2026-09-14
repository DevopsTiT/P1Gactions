# Investigation

| Checked | Finding |
| --- | --- |
| Open YAML | 4 JS tasks; `onProblemClose: false` |
| Close YAML | 1 JS task; `onProblemClose: true` |
| Open/close JSON | Same scripts and graph as YAML; flatter wrapper |
| Placeholders | `__SNOW_*__`, `__PD_ROUTING_KEY__` still present |
| Correlation | `correlation_id` + `dt-problem-<id>` shared across open/close |

Source folder: `../4-snow-pd-workflow-yaml-and-json/`
