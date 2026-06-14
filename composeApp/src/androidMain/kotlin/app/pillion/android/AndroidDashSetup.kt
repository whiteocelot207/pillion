package app.pillion.android

import android.content.Context
import app.pillion.core.DashSetup
import app.pillion.core.DashStage
import app.pillion.core.DashState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Android [DashSetup]: the one-time pair/connect via the in-app ADB bootstrap ([PillionAdb]). Casting
 * itself is automatic and lives in [CaptureService] (mirror while unlocked, dash while locked), so
 * this only handles getting the shell connection ready. Single responsibility: the setup handshake.
 */
class AndroidDashSetup(private val context: Context) : DashSetup {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _state = MutableStateFlow(DashState())
    override val state: StateFlow<DashState> = _state.asStateFlow()

    override fun pair(host: String, pairingPort: Int, code: String) {
        _state.value = DashState(DashStage.Pairing)
        scope.launch {
            runCatching { PillionAdb.getInstance(context).pairDevice(host, pairingPort, code) }
                .onSuccess { connect() }
                .onFailure { _state.value = DashState(DashStage.Error, it.message ?: "pairing failed") }
        }
    }

    override fun connect() {
        _state.value = DashState(DashStage.Connecting)
        scope.launch {
            runCatching { PillionAdb.getInstance(context).autoConnectDevice(context) }
                .onSuccess { ok ->
                    _state.value =
                        if (ok) DashState(DashStage.Connected)
                        else DashState(DashStage.Error, "Couldn't find the device — is Wireless debugging on?")
                }
                .onFailure { _state.value = DashState(DashStage.Error, it.message ?: "connect failed") }
        }
    }
}
