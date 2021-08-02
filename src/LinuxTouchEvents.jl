"""
# LinuxTouchEvents.jl

Read touch screen events from a
[Linux Input Event](https://www.kernel.org/doc/html/v4.14/input/input.html)
device.

Tested with the [Raspberry Pi Touch Display](https://www.raspberrypi.org/documentation/hardware/display/README.md).

Use this module to get touch input in terminal-mode or frame-buffer apps.

(Not intended for apps that use a high-level API like GTK/X11 or SDL.)
"""
module LinuxTouchEvents

export TouchEventChannel

using ReadmeDocs
using UnixIO
using UnixIO: C
using UnixIO.Debug


README"## Interface"

README"""
    TouchEventChannel([dev="/dev/input/event0"])

Open a channel to read touch events from a Linux Input Event device.

e.g.

    c = TouchEventChannel()
    while true
        x, y = take!(c)
        println("Touch at (\$x, \$y)")
    end
"""
struct TouchEventChannel
    io::UnixIO.FD
    width::Int
    height::Int
    function TouchEventChannel(dev="/dev/input/event0")
        size = read("/sys/class/graphics/fb0/virtual_size", String)
        new(UnixIO.open(dev, C.O_RDONLY),
            (parse(Int, x) for x in split(size, ","))...)
    end
end


# https://www.kernel.org/doc/html/v4.14/input/input.html#event-interface
struct input_event
    tv_sec::Culong
    tv_usec::Culong
    type::Cushort
    code::Cushort
    value::Cuint
end


read_event(io) = reinterpret(input_event, read(io, sizeof(input_event)))[1]


@db function wait_for_event(io, type, code, value=nothing)
    while true
        e = read_event(io)                                             ;@db 4 e
        if e.type == type &&
           e.code == code &&
           (e.value == value || value == nothing)
            @db return e.value
        end
    end
end


# https://www.kernel.org/doc/html/v4.14/input/event-codes.html#event-types
# <linux/input-event-codes.h> https://git.io/JInkG
const EV_KEY = 0x01
const BTN_TOUCH = 0x14a

const EV_ABS = 0x03
const ABS_X  = 0x00
const ABS_Y  = 0x01


@db function Base.take!(t::TouchEventChannel)
    wait_for_event(t.io, EV_KEY, BTN_TOUCH, 1)
    x = wait_for_event(t.io, EV_ABS, ABS_X)
    y = wait_for_event(t.io, EV_ABS, ABS_Y)
    @db return x/t.width, y/t.height
end


Base.close(t::TouchEventChannel) = close(t.io)



end # module
