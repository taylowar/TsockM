const std = @import("std");
const aids = @import("aids");
const cmn = aids.cmn;
const TextColor = aids.TextColor;
const Logging = @import("aids").Logging;

pub const Server = struct {
    hostname: []const u8,
    port: u16,
    address: std.net.Address,
    log_level: Logging.Level, 
    address_str: []const u8,
    start_time: std.time.Instant = undefined,
    net_server: std.net.Server = undefined,
    pub fn init(
        hostname: []const u8,
        port: u16,
        log_level: Logging.Level, 
    ) Server {
        const addr = std.net.Address.resolveIp(hostname, port) catch |err| {
            std.log.err("`server::init::addr`: {any}\n", .{err});
            std.posix.exit(1);
        };
        return Server {
            .hostname = hostname,
            .port = port,
            .log_level = log_level,
            .address = addr,
            .address_str = cmn.address_as_str(addr),
        };
    }
    pub fn start(self: *@This()) void {
        const net_server = self.address.listen(.{
            .reuse_address = true,
        }) catch |err| {
            std.log.err("`server::start::net_server`: {any}\n", .{err});
            std.posix.exit(1);
        };
        std.debug.print("Server running on `" ++ TextColor.paint_green("{s}") ++ "`\n", .{self.address_str});
        const start_time = std.time.Instant.now() catch |err| {
            std.log.err("`server::init::start_time`: {any}\n", .{err});
            std.posix.exit(1);
        };
        self.net_server = net_server;
        self.start_time = start_time;
    }
    pub fn deinit(self: *@This()) void {
        self.net_server.deinit();
    }
};
