package app.pillion.core

actual fun nowMs(): Long = System.currentTimeMillis()
actual fun sleepMs(ms: Long) { Thread.sleep(ms) }
