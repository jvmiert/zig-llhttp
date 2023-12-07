const zigllhttp = @import("zig-llhttp");
const std = @import("std");
const log = std.log.scoped(.parse);

pub fn start_message(data: *const zigllhttp.c.llhttp_t) callconv(.C) c_int {
    log.info("start_message callback: {any}", .{data.*});
    return 0;
}

pub fn on_complete(data: *const zigllhttp.c.llhttp_t) callconv(.C) c_int {
    log.info("on_message_complete callback: {any}", .{data.*});
    return 0;
}

pub fn main() !void {
    const GPA = std.heap.GeneralPurposeAllocator(.{});
    var gpa: GPA = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var settings = std.mem.zeroInit(zigllhttp.struct_llhttp_settings_s, .{});

    settings.on_message_begin = start_message;
    settings.on_message_complete = on_complete;

    var parser = try zigllhttp.LlhttpParser.init(alloc, &settings, .both);
    defer parser.deinit(alloc);

    const request: []const u8 = "GET / HTTP/1.1\r\n\r\n";

    const result = parser.execute(request);

    log.info("parser result: {}", .{result});
}
