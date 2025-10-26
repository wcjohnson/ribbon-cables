# Ribbon Cables


Ribbon cables multiplex 16 circuit network wires (8 red, 8 green) using 1x1 entities that connect to each other using a customized cable network. This allows you to:

- Fit more circuitry into smaller spaces.
- Move more information over long distances.
- Connect smart factory modules compactly using single data cables rather than a lot of power poles.
- **Actual zero UPS impact** - No polling or on-tick code. The simulated wire connections are accomplished using hidden script wires, which have the same speed as actual wire connections.
- **Full flip, rotation, copy/paste, blueprinting, overlap, and undo support** thanks to the magic of Things.

## How to Use:

1) Research the "Ribbon Cables" tech and craft two Multiplexers from the researched recipe.
2) Place them in the world, like so:

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/place-multiplexers.png)

3) Find the Ribbon Cable Connection Tool in your toolbox:

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/tool-in-toolbar.png)

4) Create a connection between your two placed Multiplexers, just as you would a circuit wire:

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/connecting.png)

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/connected.png)

5) You're done! Devices connected to corresponding pins on your multiplexers are now all on the same circuit.

![Image](https://raw.githubusercontent.com/wcjohnson/ribbon-cables/main/doc/operational.png)

You can build any size network of Multiplexers and they will all mutually connect. The pins are connected by number; to see corresponding pin numbers, just mouse over the Multiplexer.

## Contributing

Please use the [GitHub repository](https://github.com/wcjohnson/ribbon-cables) for questions, bug reports, or pull requests.
