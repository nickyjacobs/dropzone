# Boxes

Needs the [Dataview](https://github.com/blacksmithgu/obsidian-dataview) community plugin.

```dataview
TABLE status, ip, updated
FROM "Boxes"
WHERE contains(tags, "box")
SORT updated DESC
```
