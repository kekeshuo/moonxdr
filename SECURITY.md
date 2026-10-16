# Security and limits

Treat all wire inputs as hostile. Use bounded `Limits`; do not interpret an XDR
length as an allocation instruction. Resource caps, strict padding and exact
consumption are defenses, not a guarantee of safety for arbitrary applications.
An error has an offset local to the current schema or wire operation, not a global
network-stream offset. Schema bounds do not override runtime limits.

AUTH_SYS asserts uid/gid and is **not authentication**. This package verifies
syntax only; it cannot establish identities, authorize operations, detect replay,
protect confidentiality, validate signatures or make a network service secure.
Do not deploy it as an authentication service. Unknown flavor/status preservation
is for wire analysis, not acceptance by an RPC server.

Schemas and values contain public array containers. Do not mutate returned Type
arrays after validation or mutate Value/bytes concurrently with encoding. Build a
new schema for independent operations. Reader input and completed output buffers
are owned copies. There are no shared global registries or global configuration.

`RecordDecoder` is a single-stream mutable state machine, not thread-safe. On any
feed/finish error discard it and the stream; do not attempt resynchronization.
It permits repeated empty fragments only within the configured fragment budget.
Keep transport timeouts and total connection/message limits in the caller.

Limits reduce memory/work but are not constant-time protections. Graph analysis
and union/enum lookup may still take work proportional to schema size; a bounded
schema work budget rejects pathological fixed-point cases. No benchmark or formal
verification is claimed. Report reproducible bugs without credentials or private
data using the repository issue tracker.
