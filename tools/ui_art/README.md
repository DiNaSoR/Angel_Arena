# UI art

Painted art for the team select, hero selection, strategy and shop screens.

| Shipped file (`content/angel_arena/panorama/images/custom_game/arena_ui/`) | Used by |
|---|---|
| `pledge_backdrop.png` | Team select backdrop (drawn by the loading screen layer) |
| `hall_backdrop.png` | Hero selection and strategy backdrop |
| `sigil_angels.png`, `sigil_demons.png` | Team crests on all three pregame screens |
| `divider.png` | Ornament under the team select title |
| `frame_corner.png` | Corners of the hero inspector |
| `armory_strip.png` | Recipe area of the shop |

## Regenerating

The images were generated with Azure `gpt-image-2.5-sunburst` and `gpt-image-2.5-flare`.
`prompts.json` holds the prompt, model and size for each one; `generation_log.json` records
the settings and request id of every run.

```
python tools/ui_art/generate_ui_art.py --out <raw dir> [name ...]
python tools/ui_art/process_ui_art.py <raw dir>
```

`generate_ui_art.py` reads the API key from `AZURE_AI_FOUNDRY_API_KEY` (falling back to
`AZURE_OPENAI_API_KEY`, then `AZURE_API_KEY`) and never writes it anywhere.
`process_ui_art.py` needs Pillow. It crops the backdrops to 16:9, trims the transparent
ornaments, and cuts `armory_strip.png` out of the `armory_header` painting.
