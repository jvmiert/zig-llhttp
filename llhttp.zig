pub const c = @cImport({
    @cInclude("llhttp.h");
});
const std = @import("std");
const Allocator = std.mem.Allocator;
const log = std.log.scoped(.llhttp);

pub const llhttp_cb = ?*const fn (*const c.llhttp_t) callconv(.C) c_int;
pub const llhttp_data_cb = ?*const fn (*const c.llhttp_t, [*c]const u8, usize) callconv(.C) c_int;

pub const LlhttpParserType = enum { both, request, response };

pub const struct_llhttp_settings_s = extern struct {
    on_message_begin: llhttp_cb = null,
    on_url: llhttp_data_cb = null,
    on_status: llhttp_data_cb = null,
    on_method: llhttp_data_cb = null,
    on_version: llhttp_data_cb = null,
    on_header_field: llhttp_data_cb = null,
    on_header_value: llhttp_data_cb = null,
    on_chunk_extension_name: llhttp_data_cb = null,
    on_chunk_extension_value: llhttp_data_cb = null,
    on_headers_complete: llhttp_cb = null,
    on_body: llhttp_data_cb = null,
    on_message_complete: llhttp_cb = null,
    on_url_complete: llhttp_cb = null,
    on_status_complete: llhttp_cb = null,
    on_method_complete: llhttp_cb = null,
    on_version_complete: llhttp_cb = null,
    on_header_field_complete: llhttp_cb = null,
    on_header_value_complete: llhttp_cb = null,
    on_chunk_extension_name_complete: llhttp_cb = null,
    on_chunk_extension_value_complete: llhttp_cb = null,
    on_chunk_header: llhttp_cb = null,
    on_chunk_complete: llhttp_cb = null,
    on_reset: llhttp_cb = null,
};

pub extern fn llhttp_settings_init(settings: *const struct_llhttp_settings_s) void;
pub extern fn llhttp_init(parser: *c.llhttp_t, @"type": c.llhttp_type_t, settings: *const struct_llhttp_settings_s) void;
pub extern fn llhttp_execute(parser: *c.llhttp_t, data: [*c]const u8, len: usize) c.llhttp_errno_t;

pub const LlhttpParser = struct {
    parser: *c.llhttp_t,

    @"error": *i32,
    reason: [*c]const u8,
    error_pos: [*c]const u8,
    data: ?*anyopaque,
    content_length: *u64,
    type: *u8,
    method: *u8,
    http_major: *u8,
    http_minor: *u8,
    header_state: *u8,
    lenient_flags: *u16,
    upgrade: *u8,
    finish: *u8,
    flags: *u16,
    status_code: *u16,
    initial_message_completed: *u8,

    pub fn init(alloc: Allocator, settings: *const struct_llhttp_settings_s, parse_type: LlhttpParserType) !LlhttpParser {
        const parser = try alloc.create(c.llhttp_t);

        llhttp_init(parser, @intFromEnum(parse_type), settings);

        return .{
            .parser = parser,
            .@"error" = &parser.@"error",
            .reason = parser.reason,
            .error_pos = parser.error_pos,
            .data = parser.data,
            .content_length = &parser.content_length,
            .type = &parser.type,
            .method = &parser.method,
            .http_major = &parser.http_major,
            .http_minor = &parser.http_minor,
            .header_state = &parser.header_state,
            .lenient_flags = &parser.lenient_flags,
            .upgrade = &parser.upgrade,
            .finish = &parser.finish,
            .flags = &parser.flags,
            .status_code = &parser.status_code,
            .initial_message_completed = &parser.initial_message_completed,
        };
    }

    pub fn deinit(self: *LlhttpParser, alloc: Allocator) void {
        alloc.destroy(self.parser);
        self.* = undefined;
    }

    pub fn execute(self: LlhttpParser, request: []const u8) u32 {
        return llhttp_execute(self.parser, request.ptr, request.len);
    }
};
