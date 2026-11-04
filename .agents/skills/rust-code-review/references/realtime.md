# Realtime, DSP, and Shared-Memory Review Reference

## Runtime constraints

Realtime callbacks must avoid steady-state allocation, container growth, locks,
blocking, I/O, logging, and system calls. Prefer pre-allocated buffers and
bounded handoff between callback, worker, and UI threads. For DSP/render paths
with an allocation-free project contract, look for hidden formatting, cloning,
collection, and recreation of images, meshes, or textures. Do not impose that
contract on every ordinary UI path without project evidence.

Check latency, scheduling, signal dependency order, phase, indexing, transform
and window domains, thresholds, stream epochs, and reset/catch-up behavior.
Use deterministic reference signals and explicit justified float tolerances.
Optimized/parallel paths need scalar/reference equivalence: bit identity when
discrete result mapping requires it, otherwise an explicit tolerance. Measure
small-input crossover thresholds when selecting optimized paths.

## IPC and shared memory

Validate magic, version, size, capacity, offsets, and sample counts before
trusting shared-memory input. Treat external IDs, headers, and buffers as
untrusted. Document bounds, producer/consumer ownership, lifetimes, atomic
ordering, and behavior under disconnect, overflow, loss, or invalid handles.
Keep platform/backend details outside reusable signal-processing logic.

## Additional score caps

| Condition | Maximum score |
| --- | --- |
| A realtime callback, or another path with an allocation-free/nonblocking contract, allocates, locks, logs, blocks, performs I/O, or grows containers in steady state | 2 |
| DSP math, transforms, or windowing change without a breakpoint test or strong existing coverage | 3 |
| IPC/shared-memory input is trusted without size/version/bounds validation | 2 |

Performance, signal correctness, and transport integrity are separate claims;
require evidence for each claim the change makes.
