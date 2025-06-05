// this program is only valid for Windows at the moment i was looking for
// something like Rust's 'crossterm' library, but the Zig ecosystem is really
// small and there isn't any terminal library powerful enough yet for this so i
// am just using Windows API direct

pub const WinBool = i32;
pub const WinInt = i32;
pub const WinKeyReturn = i16;

pub const WINFALSE: WinBool = 0;
pub const WINKEYFALSE: WinKeyReturn = 0;

pub const MOUSE_LBUTTON = 0x01;
pub const VK_ESCAPE = 0x1b;
pub const VK_W = 0x57;
pub const VK_A = 0x41;
pub const VK_S = 0x53;
pub const VK_D = 0x44;

pub const WinPoint = extern struct {
    x: i32,
    y: i32,
};

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getcursorpos
pub extern "User32" fn GetCursorPos(point: *WinPoint) WinBool;

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setcursorpos
pub extern "User32" fn SetCursorPos(x: WinInt, y: WinInt) WinBool;

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getasynckeystate
pub extern "User32" fn GetAsyncKeyState(virtual_key: WinInt) WinKeyReturn;
