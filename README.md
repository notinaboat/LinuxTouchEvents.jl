# LinuxTouchEvents.jl

Read touch screen events from a [Linux Input Event](https://www.kernel.org/doc/html/v4.14/input/input.html) device.

Tested with the [Raspberry Pi Touch Display](https://www.raspberrypi.org/documentation/hardware/display/README.md).

Use this module to get touch input in terminal-mode or frame-buffer apps.

(Not intended for apps that use a high-level API like GTK/X11 or SDL.)


## Interface

    TouchEventChannel([dev="/dev/input/event0"])

Open a channel to read touch events from a Linux Input Event device.

e.g.

    c = TouchEventChannel()
    while true
        x, y = take!(c)
        println("Touch at (\$x, \$y)")
    end



