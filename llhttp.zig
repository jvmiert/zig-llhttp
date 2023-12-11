pub const c = @cImport({
    @cInclude("llhttp.h");
});
const std = @import("std");
const Allocator = std.mem.Allocator;
const log = std.log.scoped(.llhttp);

const Callbacks = enum {
    on_message_begin,
    on_headers_complete,

    on_message_complete,
    on_url_complete,
    on_status_complete,
    on_method_complete,
    on_version_complete,
    on_header_field_complete,
    on_header_value_complete,
    on_chunk_extension_name_complete,
    on_chunk_extension_value_complete,

    on_chunk_header,
    on_chunk_complete,
    on_reset,
};

const DataCallbacks = enum {
    on_url,
    on_status,
    on_method,
    on_version,
    on_header_field,
    on_header_value,
    on_chunk_extension_name,
    on_chunk_extension_value,
    on_body,
};

pub const LlhttpParserType = enum { both, request, response };

pub fn Zigllhttp(comptime Data: type) type {
    return struct {
        const Self = @This();

        data: Data,
        c_settings: *c.struct_llhttp_settings_s,
        parser: *c.llhttp_t,

        pub fn init(data: Data, alloc: Allocator) !Self {
            const dataInfo = @typeInfo(Data);
            if (dataInfo != .Pointer) @compileError("data must be a pointer type");

            const c_settings = try alloc.create(c.struct_llhttp_settings_s);
            const parser = try alloc.create(c.llhttp_t);

            c.llhttp_settings_init(@ptrCast(c_settings));

            return .{
                .data = data,
                .c_settings = c_settings,
                .parser = parser,
            };
        }

        pub fn add_data_callback(self: *Self, name: DataCallbacks, comptime callback: *const fn (Data, *const c.llhttp_t, [*]const u8, usize) c_int) void {
            const CWrapper = struct {
                pub fn wrapper(parser: [*c]const c.llhttp_t, data: [*c]const u8, size: usize) callconv(.C) c_int {
                    return @call(.always_inline, callback, .{ @as(Data, @ptrCast(@alignCast(parser.*.data))), parser, data, size });
                }
            };

            switch (name) {
                .on_url => {
                    self.c_settings.on_url = CWrapper.wrapper;
                },

                .on_status => {
                    self.c_settings.on_status = CWrapper.wrapper;
                },

                .on_method => {
                    self.c_settings.on_method = CWrapper.wrapper;
                },

                .on_version => {
                    self.c_settings.on_version = CWrapper.wrapper;
                },

                .on_header_field => {
                    self.c_settings.on_header_field = CWrapper.wrapper;
                },

                .on_header_value => {
                    self.c_settings.on_header_value = CWrapper.wrapper;
                },

                .on_chunk_extension_name => {
                    self.c_settings.on_chunk_extension_name = CWrapper.wrapper;
                },

                .on_chunk_extension_value => {
                    self.c_settings.on_chunk_extension_value = CWrapper.wrapper;
                },

                .on_body => {
                    self.c_settings.on_body = CWrapper.wrapper;
                },
            }
        }

        pub fn add_callback(self: *Self, name: Callbacks, comptime callback: *const fn (Data, *const c.llhttp_t) c_int) void {
            const CWrapper = struct {
                pub fn wrapper(parser: [*c]const c.llhttp_t) callconv(.C) c_int {
                    return @call(.always_inline, callback, .{ @as(Data, @ptrCast(@alignCast(parser.*.data))), parser });
                }
            };

            switch (name) {
                .on_message_begin => {
                    self.c_settings.on_message_begin = CWrapper.wrapper;
                },

                .on_headers_complete => {
                    self.c_settings.on_headers_complete = CWrapper.wrapper;
                },

                .on_message_complete => {
                    self.c_settings.on_message_complete = CWrapper.wrapper;
                },

                .on_url_complete => {
                    self.c_settings.on_url_complete = CWrapper.wrapper;
                },

                .on_status_complete => {
                    self.c_settings.on_status_complete = CWrapper.wrapper;
                },

                .on_method_complete => {
                    self.c_settings.on_method_complete = CWrapper.wrapper;
                },

                .on_version_complete => {
                    self.c_settings.on_version_complete = CWrapper.wrapper;
                },

                .on_header_field_complete => {
                    self.c_settings.on_header_field_complete = CWrapper.wrapper;
                },

                .on_header_value_complete => {
                    self.c_settings.on_header_value_complete = CWrapper.wrapper;
                },

                .on_chunk_extension_name_complete => {
                    self.c_settings.on_chunk_extension_name_complete = CWrapper.wrapper;
                },

                .on_chunk_extension_value_complete => {
                    self.c_settings.on_chunk_extension_value_complete = CWrapper.wrapper;
                },

                .on_chunk_header => {
                    self.c_settings.on_chunk_header = CWrapper.wrapper;
                },

                .on_chunk_complete => {
                    self.c_settings.on_chunk_complete = CWrapper.wrapper;
                },

                .on_reset => {
                    self.c_settings.on_reset = CWrapper.wrapper;
                },
            }
        }

        pub fn parse(self: *Self, parse_type: LlhttpParserType, data: []const u8) u32 {
            c.llhttp_init(self.parser, @intFromEnum(parse_type), self.c_settings);
            self.parser.*.data = @ptrCast(@alignCast(self.data));

            return c.llhttp_execute(self.parser, data.ptr, data.len);
        }

        pub fn deinit(self: *Self, alloc: Allocator) void {
            alloc.destroy(self.c_settings);
            alloc.destroy(self.parser);
            self.* = undefined;
        }
    };
}
