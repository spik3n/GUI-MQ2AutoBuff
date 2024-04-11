# GUIAutoBuff for MQ2AutoBuff Plugin

This project provides a graphical user interface for the MQ2AutoBuff plugin, which is part of the MacroQuest suite. Implemented in Lua and utilizing the ImGui library, this GUI simplifies the management and configuration of the MQ2AutoBuff plugin through an easy-to-use interface.

## Features

- **Intuitive Graphical Interface**: Allows easy access to all features of the MQ2AutoBuff plugin through ImGui.
- **Dynamic Configuration Loading**: Automatically generates and manages configuration settings specific to your server and character.
- **Real-time Control**: Start, stop, and manage buffing operations directly from the GUI.
- **Command Management**: Execute and manage buff commands with simple clicks instead of typing commands manually.
- **Debug Support**: Easily toggle debug modes to monitor the operations of the MQ2AutoBuff plugin.
- **Show ini [MQ2AutoBuff] part**: Show [MQ2AutoBuff] part in ini file in real time.
- **Edit ini [MQ2AutoBuff] part**: Easily edit [MQ2AutoBuff] part in ini file in real time.


## Installation

To install the GUIAutoBuff for MQ2AutoBuff:

1. Place the GUIAutoBuff files into the appropriate MacroQuest `Lua` directory.
2. Load the GUI from the Lua interface


## Usage

The GUI can be accessed and used within the game after loading the plugin. It provides buttons and text fields to interact with the MQ2AutoBuff plugin commands, such as:

- **`/ab`**: Toggle the processing of the buff queue.
- **`/db <name> <buff>`**: Add a buff to the queue for a specific name.
- **`/tb <buff>`**: Add a buff to the queue for your current target.
- **`/dq`**: Display all buffs in the queue.
- **`/cq`**: Clear the buff queue.
- **`/abc`**: Open the user control status screen.

## Configuration

The GUI interacts with configuration settings stored in an INI file, which is named based on your server and character. This ensures that settings are unique and persistent across sessions. The GUI allows you to edit these settings directly through a dedicated "Edit INI" window.

## Known Issues

- **Unsaved Changes Alert**: There is a known bug where the confirmation window for unsaved changes may incorrectly appear the second time you click on "Add Buff", even if no new data has been entered. This issue is under investigation and will be addressed in future updates.

## Contributing

Feel free to contribute to the development of GUIAutoBuff by submitting pull requests or reporting bugs and feature requests through the GitHub project page.


## Use code
I have included detailed comments throughout the code to assist new users in easily navigating and modifying it according to their needs. Feel free to utilize this code as a base for your own projects. This project was initially a test to explore Lua's capabilities and experiment with various programming approaches. It serves as a practical example of what can be achieved and how different methods can be applied in a real-world application.

## License

This project is released under the MIT License - see the LICENSE file for details.