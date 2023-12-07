const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const llhttp = b.dependency("llhttp", .{ .target = target, .optimize = optimize });

    const lib = b.addStaticLibrary(.{
        .name = "zig-llhttp",
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();

    lib.addIncludePath(llhttp.path("include"));
    const header_path = llhttp.path("include/llhttp.h").getPath(b);
    lib.installHeader(header_path, "llhttp.h");

    const csources = [_][]const u8{
        "api.c",
        "http.c",
        "llhttp.c",
    };

    inline for (csources) |csrc| {
        lib.addCSourceFile(.{
            .file = llhttp.path("src/" ++ csrc),
            .flags = &[_][]const u8{ "-Wall", "-Wextra", "-O3" },
        });
    }

    b.installArtifact(lib);

    const zigllhttp = b.addModule("zig-llhttp", .{ .source_file = .{ .path = "llhttp.zig" } });

    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = .{ .path = "example.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.addModule("zig-llhttp", zigllhttp);
    exe.addIncludePath(llhttp.path("include"));
    exe.linkLibrary(lib);
    b.installArtifact(exe);
}
