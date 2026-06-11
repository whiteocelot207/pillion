package app.pillion.ui

import androidx.compose.runtime.Composable

/** Intercepts the system back gesture (Android); a no-op on platforms without one. */
@Composable
expect fun BackHandler(enabled: Boolean, onBack: () -> Unit)
