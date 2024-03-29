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
    buffer::Channel{Tuple{Float64, Float64}}
    function TouchEventChannel(dev="/dev/input/event0")
        size = read("/sys/class/graphics/fb0/virtual_size", String)
        new(UnixIO.open(dev, C.O_RDONLY),
            (parse(Int, x) for x in split(size, ","))...,
            Channel{Tuple{Float64, Float64}}(1))
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


function read_event(io)
    x = read(io, sizeof(input_event))
    return isempty(x) ? nothing : reinterpret(input_event, x)[1]
end


function wait_for_event(io, type, code, value=nothing)
    while true
        e = read_event(io)
        if e == nothing
            return e
        end
        if e.type == type &&
           e.code == code &&
           (e.value == value || value == nothing)
            return e.value
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

function wait_for_touch(t)
    wait_for_event(t.io, EV_KEY, BTN_TOUCH, 1)
end


function wait_for_touch_coordinates(t)
    x = wait_for_event(t.io, EV_ABS, ABS_X)
    y = wait_for_event(t.io, EV_ABS, ABS_Y)
    return x/t.width, y/t.height
end


function Base.take!(t::TouchEventChannel)
    if isready(t.buffer)
        return take!(t.buffer)
    end
    wait_for_touch(t)
    wait_for_touch_coordinates(t)
end


function Base.isready(t::TouchEventChannel; timeout=0)
    if isempty(t.buffer)
        UnixIO.set_timeout(t.io, timeout)
        touch = wait_for_touch(t)
        UnixIO.set_timeout(t.io, Inf)
        if touch != nothing
            put!(t.buffer, wait_for_touch_coordinates(t))
        end
    end

    return isready(t.buffer)
end


Base.close(t::TouchEventChannel) = close(t.io)



end # module
