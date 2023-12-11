const zigllhttp = @import("zig-llhttp");
const std = @import("std");
const Allocator = std.mem.Allocator;
const log = std.log.scoped(.parse);

const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };

const Server = struct {
    parser: zigllhttp.Zigllhttp(*Server),
    allocator: Allocator,

    some_data: [5]u8,

    pub fn init(alloc: Allocator) !Server {
        var server: Server = .{
            .allocator = alloc,
            .parser = undefined,
            .some_data = message,
        };

        server.parser = try zigllhttp.Zigllhttp(*Server).init(&server, alloc);

        server.parser.add_callback(.on_message_begin, on_message_begin);
        server.parser.add_callback(.on_headers_complete, on_headers_complete);

        server.parser.add_data_callback(.on_url, on_url);

        return server;
    }

    pub fn on_message_begin(server: *Server, data: *const zigllhttp.c.llhttp_t) c_int {
        _ = data;
        log.info("on_message_complete callback: {s}", .{server.some_data});
        return 0;
    }

    pub fn on_headers_complete(server: *Server, data: *const zigllhttp.c.llhttp_t) c_int {
        _ = data;
        log.info("on_headers_complete callback: {s}", .{server.some_data});
        return 0;
    }

    fn on_url(server: *Server, _: *const zigllhttp.c.llhttp_t, data: [*]const u8, size: usize) c_int {
        log.info("on_url: {s} - {s}", .{ server.some_data, data[0..size] });
        return 0;
    }

    pub fn parse(self: *Server, request: []const u8) void {
        const result = self.parser.parse(.both, request);
        log.info("parse result: {d}", .{result});
    }

    pub fn deinit(self: *Server) void {
        self.parser.deinit(self.allocator);
    }
};

pub fn main() !void {
    const GPA = std.heap.GeneralPurposeAllocator(.{});
    var gpa: GPA = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var server = try Server.init(alloc);

    const request: []const u8 = "GET /cool-url HTTP/1.1\r\n\r\n";

    server.parse(request);

    server.deinit();
}
