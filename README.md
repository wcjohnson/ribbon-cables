# Ribbon Cables

**This mod is currently in BETA.**

Ribbon cables multiplex up to 16 red and green circuit connection pins using 1x1 entities that connect to each other using a customized cable network. This allows you to:

- Fit more circuitry into smaller spaces.
- Move more information over long distances.
- Connect smart factory modules compactly using single data cables rather than a lot of power poles.

Other neat features:

- **No scripted UPS impact** - No polling or on-tick code. The virtual wire connections are accomplished using hidden script wires between power poles and have the same UPS impact as the equivalent vanilla Factorio construction.
- **Full flip, rotation, copy/paste, blueprinting, overlap, and undo support.**

## How to Use:

1) Research the "Ribbon Cables" tech and craft two Multiplexers from the researched recipe.
2) Place them in the world, like so:

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/place-multiplexers.png)

3) Click on the multiplexers and select the number of desired pins. (Copy/pasting from a single multiplexer makes this faster.)
4) Find the Ribbon Cable Connection Tool in your toolbox:

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/tool-in-toolbar.png)

5) Create a connection between your two placed Multiplexers, just as you would a circuit wire:

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/connecting.png)

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/connected.png)

6) You're done! Devices connected to corresponding pins on your multiplexers are now all on the same circuit.

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/operational.png)

You can build any size network of Multiplexers and they will all mutually connect. The pins are connected by number; to see corresponding pin numbers, just mouse over the Multiplexer.

Clicking on a Multiplexer gives a window with some additional options:

- **Pin Labels** - Each pin may be given a richtext label that will replace the number when hovered.
- **Connection Key** - If a key string is entered here, this multiplexer can only connect to others that have the same key string.

## Credits

- **hgschmie** for the excellent Fiber Optics mod which inspired this mod. My main problem with Fiber Optics was its use of the electrical network, hence the custom ribbon cable network introduced in this mod.

## Contributing

Please use the [GitHub repository](https://github.com/wcjohnson/ribbon-cables) for questions, bug reports, or pull requests.
