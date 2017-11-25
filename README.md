# holyc_mal
Mal for TempleOS. Developed on TempleOS v5.03 running in VirtualBox.

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
evaluation of terms (e.g., when self-hosting the main term never terminates),
intermediate values not reachable from the global environment must be pushed
onto a special GC stack to prevent them from being erroneously collected.

There is a rudimentary regular expression engine in Regex.HC based on
Brzozowski derivatives rather than finite automata.

Array.HC provides a generic dynamic array which is used internally by PArray (arrays of pointers), and String.

Lists are implemented as a simple cons/nil style linked list. Hashmaps are
just association lists (but backed by arrays), so performance could probably be
improved by implementing actual hash tables or some balanced binary tree
structure with string interning.

There are a bunch of "unnecessary" safety checks for null pointers, but they're
useful for debugging.

One problem is that the default stack size for programs is relatively small in
TempleOS, so the maximum recursion depth is limited. It may sometimes be
necessary to rewrite functions to be tail-recursive when it wouldn't be an
issue in other implementations. I haven't found a way to increase the stack
size yet -- it may actually require a patch to the HolyC compiler or OS.


## Performance benchmarks
Running in a VirtualBox VM. CPU is i7-4790k.
- perf1.mal: 11 ms
- perf2.mal: 66 ms
- perf3.mal: 192 iters/s
