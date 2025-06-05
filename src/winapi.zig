// this program is only valid for Windows at the moment i was looking for
// something like Rust's 'crossterm' library, but the Zig ecosystem is really
// small and there isn't any terminal library powerful enough yet for this so i
// am just using Windows API direct

pub fn showCursor() void {
    while (ShowCursor(WIN_NOT_FALSE) < 0) {
        continue;
    }
}

pub fn hideCursor() void {
    while (ShowCursor(WIN_FALSE) >= 0) {
        continue;
    }
}

// https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types
pub const WinBool = i32;
pub const WinInt = i32;
pub const WinKeyReturn = i16;
pub const WinDWord = i16;
pub const WinHandle = *opaque {};
pub const WinShort = i16;

// https://learn.microsoft.com/en-us/windows/console/getstdhandle
pub const WIN_STD_HANDLE = -11;

pub const WIN_FALSE: WinBool = 0;
pub const WIN_NOT_FALSE: WinBool = 999999;
pub const WIN_KEY_FALSE: WinKeyReturn = 0;
pub const WIN_CONSOLE_CURRENT: WinBool = WIN_FALSE;

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getasynckeystate
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

pub const WinCoord = extern struct {
    x: WinShort,
    y: WinShort,
};

// https://learn.microsoft.com/en-us/windows/console/small-rect-str
pub const WinSmallRect = extern struct {
    left: WinShort,
    right: WinShort,
    top: WinShort,
    bottom: WinShort,
};

// https://learn.microsoft.com/en-us/windows/console/getconsolescreenbufferinfo
pub const WinConsoleInfo = extern struct {
    window_size: WinCoord,
    cursor_pos: WinCoord,
    attributes: WinDWord,
    sr_window: WinSmallRect,
    max_size: WinCoord,
};

// https://learn.microsoft.com/en-us/windows/console/console-font-info-str
pub const WinConsoleFontInfo = extern struct {
    font_index: WinDWord,
    font_char_size: WinCoord,
};

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getcursorpos
pub extern "User32" fn GetCursorPos(point: *WinPoint) WinBool;

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setcursorpos
pub extern "User32" fn SetCursorPos(x: WinInt, y: WinInt) WinBool;

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getasynckeystate
pub extern "User32" fn GetAsyncKeyState(virtual_key: WinInt) WinKeyReturn;

// https://learn.microsoft.com/en-us/windows/console/getstdhandle
pub extern "Kernel32" fn GetStdHandle(std_handle: WinDWord) WinHandle;

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showcursor
extern "User32" fn ShowCursor(toggle_show: WinBool) WinInt;

// https://learn.microsoft.com/en-us/windows/console/getconsolescreenbufferinfo
pub extern "Kernel32" fn GetConsoleScreenBufferInfo(
    console_handle: WinHandle,
    console_info: *WinConsoleInfo,
) WinBool;

// https://learn.microsoft.com/en-us/windows/console/getcurrentconsolefont
pub extern "Kernal32" fn GetCurrentConsoleFont(
    std_handle: WinDWord,
    max_window: WinBool,
    *WinConsoleFontInfo,
) WinBool;
