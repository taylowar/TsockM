const std = @import("std");
const print = std.debug.print;
const aids = @import("aids");
const sc = @import("server.zig");
const pc = @import("peer.zig");
const SharedData = @import("shared-data.zig").SharedData;

const str_allocator = std.heap.page_allocator;

const hostname = "127.0.0.1";
const port = 8888;

var tmp = std.heap.GeneralPurposeAllocator(.{}){};
const gpa_allocator = tmp.allocator();
var server: sc.Server = undefined;
test "Server.init" {
    server = sc.Server.init(gpa_allocator, str_allocator, hostname, port, .DEV, "");
    try std.testing.expectEqualStrings("127.0.0.1:8888", server.address_str);
}

fn testingStream() !std.net.Stream {
    const addr = try std.net.Address.resolveIp(server.hostname, server.port);
    if (std.net.tcpConnectToAddress(addr)) |s| {
        return s;
    } else |err| {
        const sep = "\n------------------------------------------------------------------";
        std.log.err(
            sep ++ "\nFailed to connect to testing server. Make sure it is running!\n" ++ "expected: `127.0.0.1:8888`" ++ sep,
            .{},
        );
        return err;
    }
}

var user_id: []const u8 = "";
var comm_stream: std.net.Stream = undefined;
test "Server.Action.COMM" {
    comm_stream = try testingStream();
    const username = "milko";
    const reqp = aids.proto.Protocol.init(.REQ, .COMM, .OK, "tester", server.address_str, server.address_str, username);
    _ = aids.proto.transmit(comm_stream, reqp);
    const resp = try aids.proto.collect(str_allocator, comm_stream);
    try std.testing.expectEqual(aids.proto.Typ.RES, resp.type);
    try std.testing.expectEqual(aids.proto.Act.COMM, resp.action);
    try std.testing.expectEqual(aids.proto.StatusCode.OK, resp.status_code);
    var splits = std.mem.splitScalar(u8, resp.body, '|');
    user_id = splits.next().?;
    var unns = std.mem.splitScalar(u8, splits.next().?, '#');
    const og_name = unns.first();
    try std.testing.expectEqualStrings(username, og_name);
}

test "Server.Action.MSG" {
    const stream = try testingStream();
    const reqp = aids.proto.Protocol.init(.REQ, .MSG, .OK, user_id, server.address_str, server.address_str, "Ojla");
    _ = aids.proto.transmit(stream, reqp);
    const resp = try aids.proto.collect(str_allocator, comm_stream);
    try std.testing.expectEqual(aids.proto.Typ.RES, resp.type);
    try std.testing.expectEqual(aids.proto.Act.MSG, resp.action);
    try std.testing.expectEqual(aids.proto.StatusCode.OK, resp.status_code);
    try std.testing.expect(true);
}
