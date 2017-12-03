<a href="TempleOS"><img src="TOS_logo.png" align="left" height="180" ></a>
# Mal for TempleOS.
A complete implementation (with garbage collection) of the [Mal](https://github.com/kanaka/mal)
dialect of Lisp for TempleOS v5.03 written in HolyC.
Mal includes macro support, tail-call optimization, file I/O, metadata on values,
Clojure-style mutable reference atoms, and more. For more information about Mal,
visit the [main repository](https://github.com/kanaka/mal).
<br>

## Easy setup

A Docker image is available and can be run with the following command:

```
sudo docker run -it --privileged --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /root/.Xauthority:/root/.Xauthority:rw bagnalla/mal-holyc:v1
```

If you see something like "could not initialize SDL", run the command `xhost +`
and try again. Afterward, do `xhost -` to restore the original setting.

If you don't wish to use the Docker image, you can follow the steps below.

## Installation

Here is one way to copy the files over to a TOS installation using qemu-nbd.
First, mount the disk image:
```
sudo modprobe nbd max_part=16
sudo qemu-nbd -c /dev/nbd0 TempleOS.vdi
sudo partprobe /dev/nbd0
sudo mount /dev/nbd0p1 /mnt
```

Where 'TempleOS.vdi' is replaced with the name of your image.
Then, copy the files to /mnt/Home/Mal or wherever you would like.

Finally, unmount the image:
```
sudo umount /mnt
sudo qemu-nbd -d /dev/nbd0
```

## Running Mal

Just include the file "Interp.HC" at the command line to bring Mal into scope.

Run the REPL:
```
mal;
```

Run a mal program 'prog.mal':
```
mal("prog.mal");
```

## Implementation info

All tests pass and self-hosting is successful
([dramatized demonstration](https://www.youtube.com/watch?v=tbr-j2_zhgU)).
The only real thing missing at the moment is HolyC interop. 

The garbage collector uses a simple mark and sweep strategy, using the
global environment as the root. Some cooperation from other parts of the code
is necessary, however. Since we must allow garbage collection to run during
evaluation of terms (e.g., when self-hosting, the main term never terminates),
intermediate values not reachable from the global environment must be pushed
onto a special GC stack to prevent them from being erroneously collected.

There is a rudimentary regular expression engine in Regex.HC based on
Brzozowski derivatives rather than finite automata.

Array.HC provides a generic dynamic array which is used internally by PArray
(arrays of pointers), and String.

Lists are implemented with a simple cons/nil linked list. Hashmaps are
just association lists (but backed by arrays), so performance could probably be
improved by implementing actual hash tables or some balanced binary tree
structure with string interning.

There are a bunch of "unnecessary" safety checks for null pointers, but they're
useful for debugging.

One problem is that the call stack for programs is relatively small in
TempleOS, so the maximum recursion depth is limited. It may sometimes be
necessary to write functions in tail-recursive form when it wouldn't be an
issue in other implementations. I haven't found a way to increase the stack
size yet -- it may actually require a patch to the HolyC compiler or OS.

I haven't yet found the analogue to ctrl+D in TempleOS, so there is a 'quit!'
special form for exiting the REPL. Just type '(quit!)'.


## Performance benchmarks
Running in a VirtualBox VM. CPU is i7-4790k.
- perf1.mal: 11 ms
- perf2.mal: 66 ms
- perf3.mal: 192 iters/s
