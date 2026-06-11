package app.pillion.core

/** Tiny platform primitives (DIP) so common code stays platform-agnostic. */
expect fun nowMs(): Long
expect fun sleepMs(ms: Long)
