# Explore: themes from the community

Settings > Appearance > Explore shows the themes listed in `index.json`. Each one is a `.dstheme` file in `themes/`
(its settings and its wallpaper) with a small picture in `previews/`. `rice-explore` only downloads files from this
repo, and it checks each one against the size and SHA-256 written in `index.json` before it is used.

## Sending yours in

1. Settings > Appearance > Explore > **Share my setup**. Your desktop is saved in `~/DarkShadow-themes`, and the
   GitHub page to send it in opens.
2. Drop the `-for-github.zip` file on that page (GitHub does not take `.dstheme` files), add a name and send it.

Only send wallpapers you made yourself or whose license lets them be shared.

## Adding one (for the maintainer)

Put the file in `themes/ID.dstheme` and a 960x540 JPG in `previews/ID.jpg`, then add an entry to `index.json`
with its `sha256` (`sha256sum themes/ID.dstheme`) and `size` (`stat -c %s themes/ID.dstheme`).

The first four themes (Polar Lights, Dunes, Orbit, Mesh) have wallpapers drawn by a script, free to use.
