const glfw = @import("zglfw");

pub const Window = struct {
    title: [:0]const u8,
    width: u32,
    height: u32,
    window: *glfw.Window,

    pub fn new(title: [:0]const u8, width: u32, height: u32) error{ GLFWError, WindowError }!Window {
        glfw.init() catch {
            return error.GLFWError;
        };

        glfw.windowHint(.context_version_major, 4);
        glfw.windowHint(.context_version_minor, 6);
        glfw.windowHint(.opengl_profile, .opengl_core_profile);

        const window = glfw.createWindow(@as(c_int, @intCast(width)), @as(c_int, @intCast(height)), title, null, null) catch {
            return error.WindowError;
        };

        glfw.makeContextCurrent(window);

        return Window{ .title = title, .width = width, .height = height, .window = window };
    }

    pub fn shouldClose(self: *const Window) bool {
        return self.window.shouldClose();
    }

    pub fn pollEvents() void {
        glfw.pollEvents();
    }

    pub fn swapBuffers(self: *Window) void {
        self.window.swapBuffers();
    }

    pub fn destroy(self: *Window) void {
        self.window.destroy();
        glfw.terminate();
    }

    pub fn getTime() f32 {
        return @as(f32, @floatCast(glfw.getTime()));
    }

    pub fn setTitle(self: *Window, title: [:0]const u8) void {
        glfw.setWindowTitle(self.window, title);
    }
};
