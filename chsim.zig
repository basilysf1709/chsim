const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

const VirtualNode = struct {
    id: u32,
    parent_id: u32,
    position: u32,
    name: [5]u8,
    ip: [16]u8,
};

const HashRing = struct {
    virtual_nodes: std.ArrayList(VirtualNode),
    virtual_nodes_per_node: u32,
    allocator: std.mem.Allocator,
    rng: std.rand.DefaultPrng,

    fn init(allocator: std.mem.Allocator, virtual_nodes_per_node: u32) HashRing {
        return HashRing{
            .virtual_nodes = std.ArrayList(VirtualNode).init(allocator),
            .virtual_nodes_per_node = virtual_nodes_per_node,
            .allocator = allocator,
            .rng = std.rand.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp()))),
        };
    }

    fn deinit(self: *HashRing) void {
        self.virtual_nodes.deinit();
    }

    fn addNode(self: *HashRing) !void {
        const parent_id = @as(u32, @intCast(self.virtual_nodes.items.len / self.virtual_nodes_per_node));
        var ip: [16]u8 = undefined;
        _ = try std.fmt.bufPrint(&ip, "192.168.{d}.{d}", .{ self.rng.random().intRangeAtMost(u8, 101, 255), self.rng.random().intRangeAtMost(u8, 1, 254) });
        ip[15] = 0;

        var i: u32 = 0;
        while (i < self.virtual_nodes_per_node) : (i += 1) {
            var name: [5]u8 = undefined;
            _ = try std.fmt.bufPrint(&name, "s{d}_{d}", .{ parent_id, i });
            name[4] = 0; // Null-terminate the name

            const virtual_node = VirtualNode{
                .id = @as(u32, @intCast(self.virtual_nodes.items.len)),
                .parent_id = parent_id,
                .position = HashRing.hash(&name),
                .name = name,
                .ip = ip,
            };
            try self.virtual_nodes.append(virtual_node);
            std.debug.print("Added node: {s}\n", .{virtual_node.name});
        }
    }

    fn removeNode(self: *HashRing) void {
        if (self.virtual_nodes.items.len >= self.virtual_nodes_per_node) {
            var i: u32 = 0;
            while (i < self.virtual_nodes_per_node) : (i += 1) {
                _ = self.virtual_nodes.popOrNull();
            }
        }
    }

    fn sortVirtualNodes(self: *HashRing) void {
        const items = self.virtual_nodes.items;
        var i: usize = 0;
        while (i < items.len - 1) : (i += 1) {
            var j: usize = 0;
            while (j < items.len - i - 1) : (j += 1) {
                if (items[j].position > items[j + 1].position) {
                    const temp = items[j];
                    items[j] = items[j + 1];
                    items[j + 1] = temp;
                }
            }
        }
    }

    fn compByPosition(_: void, a: VirtualNode, b: VirtualNode) bool {
        return a.position < b.position;
    }

    fn hash(key: []const u8) u32 {
        var h: u32 = 5381;
        for (key) |char| {
            h = ((h << 5) +% h) +% char;
        }
        h = h *% 2654435761;
        return h % 360;
    }

    fn findNode(self: *HashRing, key: []const u8) ?*VirtualNode {
        const hash_value = HashRing.hash(key);
        for (self.virtual_nodes.items) |*node| {
            if (node.position >= hash_value) {
                return node;
            }
        }
        return if (self.virtual_nodes.items.len > 0) &self.virtual_nodes.items[0] else null;
    }
};

const RequestState = struct {
    active: bool = false,
    timer: f32 = 0,
    position: u32 = 0,
    target_node: ?*VirtualNode = null,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    c.InitWindow(1024, 768, "Consistent Hashing Simulation");
    defer c.CloseWindow();

    c.SetTargetFPS(60);

    var hash_ring = HashRing.init(allocator, 3);
    defer hash_ring.deinit();

    // Add initial nodes
    try hash_ring.addNode();
    try hash_ring.addNode();
    hash_ring.sortVirtualNodes();

    var request_state = RequestState{};

    while (!c.WindowShouldClose()) {
        if (c.IsKeyPressed(c.KEY_A)) {
            try hash_ring.addNode();
            hash_ring.sortVirtualNodes();
        }
        if (c.IsKeyPressed(c.KEY_D)) {
            hash_ring.removeNode();
        }
        if (c.IsKeyPressed(c.KEY_SPACE) and !request_state.active) {
            request_state.active = true;
            request_state.timer = 2.0;
            request_state.position = hash_ring.rng.random().intRangeAtMost(u32, 0, 359);
            var key_buf: [8]u8 = undefined;
            const key = try std.fmt.bufPrint(&key_buf, "key_{d}", .{hash_ring.rng.random().int(u32)});
            request_state.target_node = hash_ring.findNode(key);
        }

        if (request_state.active) {
            request_state.timer -= c.GetFrameTime();
            if (request_state.timer <= 0) {
                request_state.active = false;
            }
        }

        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.BLACK);

        // Draw the hash ring
        const center_x: f32 = 300;
        const center_y: f32 = 384;
        const radius: f32 = 250;

        c.DrawCircleLines(@as(c_int, @intFromFloat(center_x)), @as(c_int, @intFromFloat(center_y)), radius, c.WHITE);

        for (hash_ring.virtual_nodes.items) |vnode| {
            const angle = @as(f32, @floatFromInt(vnode.position)) * std.math.pi / 180.0;
            const x = center_x + radius * @cos(angle);
            const y = center_y + radius * @sin(angle);
            c.DrawCircle(@as(c_int, @intFromFloat(x)), @as(c_int, @intFromFloat(y)), 3, c.PURPLE);

            const label_x = x + 10 * @cos(angle);
            const label_y = y + 10 * @sin(angle);
            // Only draw the virtual node name (s0_0, s0_1, etc.) without the IP
            std.debug.print("Drawn node: {s}\n", .{&vnode.name});
            c.DrawText(&vnode.name, @as(c_int, @intFromFloat(label_x)), @as(c_int, @intFromFloat(label_y)), 10, c.WHITE);
        }

        // Draw request visualization
        if (request_state.active) {
            const angle = @as(f32, @floatFromInt(request_state.position)) * std.math.pi / 180.0;
            const x = center_x + radius * @cos(angle);
            const y = center_y + radius * @sin(angle);
            c.DrawCircle(@as(c_int, @intFromFloat(x)), @as(c_int, @intFromFloat(y)), 5, c.RED);

            if (request_state.target_node) |target| {
                const target_angle = @as(f32, @floatFromInt(target.position)) * std.math.pi / 180.0;
                const target_x = center_x + radius * @cos(target_angle);
                const target_y = center_y + radius * @sin(target_angle);
                c.DrawLineEx(c.Vector2{ .x = x, .y = y }, c.Vector2{ .x = target_x, .y = target_y }, 2, c.RED);
            }
        }

        // Draw table
        const table_x: c_int = 600;
        const table_y: c_int = 50;
        const row_height: c_int = 30;
        const col_width: c_int = 200;

        c.DrawText("Virtual Node", table_x, table_y, 20, c.WHITE);
        c.DrawText("IP (Identifier)", table_x + col_width, table_y, 20, c.WHITE);

        for (hash_ring.virtual_nodes.items, 0..) |vnode, i| {
            const row_y = @as(c_int, @intCast(table_y + row_height * (@as(c_int, @intCast(i)) + 1)));
            const highlight = request_state.active and request_state.target_node == &vnode;

            if (highlight) {
                c.DrawRectangle(table_x, row_y, col_width * 2, row_height, c.DARKPURPLE);
            }

            // Draw virtual node name (s0_0, s0_1, etc.)
            c.DrawText(&vnode.name, table_x, row_y, 20, c.WHITE);

            // Draw IP address
            c.DrawText(&vnode.ip, table_x + col_width, row_y, 20, c.WHITE);
        }

        c.DrawText("Press 'A' to add a node", 10, 10, 20, c.WHITE);
        c.DrawText("Press 'D' to delete a node", 10, 40, 20, c.WHITE);
        c.DrawText("Press SPACE to send a request", 10, 70, 20, c.WHITE);
        c.DrawText(c.TextFormat("Nodes: %d", @as(c_int, @intCast(hash_ring.virtual_nodes.items.len / hash_ring.virtual_nodes_per_node))), 10, 100, 20, c.WHITE);
    }
}
