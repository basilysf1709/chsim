# Consistent Hashing Simulator (chsim)

This project is a simulation of consistent hashing using Zig and Raylib. The application visualizes how a hash ring distributes nodes and routes requests to these nodes based on hash values. It demonstrates the addition and removal of nodes in the ring and shows how requests are routed.

https://github.com/user-attachments/assets/5771304e-3829-4fec-8e63-b2b97a8afa6c

## Prerequisites

To build and run this project, you'll need:

- **Zig**: The Zig programming language. You can download it from [the official Zig website](https://ziglang.org/download/).
- **Raylib**: A C library for creating games and multimedia applications. You need to have Raylib installed and properly set up for Zig. You can find the library [here](https://www.raylib.com/).

## Building the Project

1. **Clone the Repository:**

   ```sh
   git clone https://github.com/basilysf1709/chsim.git
   cd https://github.com/basilysf1709/chsim.git
   ```

2. **Install Raylib:**

   Follow the instructions on the [Raylib installation page](https://www.raylib.com/). Ensure that `raylib.h` is accessible for your Zig build.

3. **Build & Run the Project:**

   The project uses Zig’s build system. To build the application, run:

   ```sh
   zig build run
   ```

## Usage

Once the application is running, you can interact with the simulation using the following controls:

- **Press 'A'**: Add a new virtual node to the hash ring.
- **Press 'D'**: Remove a virtual node from the hash ring.
- **Press SPACE**: Generate a request with a random key and visualize its routing to the appropriate node.

## Application Overview

### Data Structures

- **`VirtualNode`**: Represents a virtual node in the hash ring with properties like `id`, `parent_id`, `position`, `name`, and `ip`.
- **`HashRing`**: Manages the collection of virtual nodes and provides functionality to add, remove, and find nodes. It also sorts the nodes by their position on the ring.

### Functions

- **`HashRing.init`**: Initializes the hash ring with an allocator and a specified number of virtual nodes per node.
- **`HashRing.addNode`**: Adds a new node to the hash ring and sorts the nodes.
- **`HashRing.removeNode`**: Removes nodes from the hash ring if the number exceeds the specified limit.
- **`HashRing.findNode`**: Finds the appropriate node for a given key based on its hash value.
- **`HashRing.hash`**: Computes a hash value for a given key.

### Visualization

- **Nodes**: Displayed as purple circles on a ring. Their positions on the ring are determined by their hash values.
- **Requests**: Represented as red circles on the ring. The path from the request to the target node is visualized with a red arc.

## Contributing

Feel free to contribute to this project by submitting issues, improvements, or pull requests. Your feedback and suggestions are welcome!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
