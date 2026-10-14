# EasyRec icon

The EasyRec icon uses a light rounded-square tile with a coral screen frame and recording dot. Its simple silhouette is designed to remain legible in the Dock and at small sizes.

- `AppIcon.png`: master artwork with transparency outside the tile.
- `EasyRec.icns`: macOS icon generated from the master.
- `AppIcon-prompt.txt`: the generation and edge-refinement prompts.
- `Info.plist`: application identity and permission descriptions.

The artwork was created for EasyRec with the built-in image generation tool. It is included under the repository's [MIT License](../LICENSE).

To regenerate the ICNS after replacing the master artwork:

```sh
zsh scripts/build-icon.sh
zsh scripts/build-app.sh
```

The script uses macOS `sips` and `iconutil` to produce 16–1024 pixel icon representations.
