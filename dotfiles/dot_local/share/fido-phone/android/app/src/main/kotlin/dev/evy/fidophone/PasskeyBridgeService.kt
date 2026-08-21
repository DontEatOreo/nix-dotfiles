package dev.evy.fidophone

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.InetAddresses
import android.net.IpPrefix
import android.net.Uri
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException
import java.io.File
import java.io.IOException
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.security.MessageDigest
import java.util.Base64
import java.util.concurrent.Executors

class PasskeyBridgeService : Service() {
    private val serverExecutor = Executors.newSingleThreadExecutor()

    @Volatile
    private var serverSocket: ServerSocket? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(
            NOTIFICATION_ID,
            createNotification(R.string.notification_listening),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
        )
        serverExecutor.execute(::runServer)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        serverExecutor.shutdownNow()
        closeServerSocket()
        serverExecutor.close()
        super.onDestroy()
    }

    private fun runServer() {
        try {
            ServerSocket().use { listener ->
                serverSocket = listener
                listener.reuseAddress = true
                listener.bind(InetSocketAddress(PORT), LISTEN_BACKLOG)

                while (!listener.isClosed && !Thread.currentThread().isInterrupted) {
                    try {
                        listener.accept().use { client ->
                            client.soTimeout = CLIENT_TIMEOUT_MILLIS
                            handleClient(client)
                        }
                    } catch (exception: IOException) {
                        if (!listener.isClosed) {
                            Log.w(TAG, "Rejected passkey connection", exception)
                        }
                    }
                }
            }
        } catch (exception: IOException) {
            Log.e(TAG, "Passkey listener stopped", exception)
            updateNotification(R.string.notification_listener_failed)
        } finally {
            serverSocket = null
        }
    }

    private fun handleClient(client: Socket) {
        val output = DataOutputStream(client.getOutputStream())
        val status = try {
            processRequest(client)
        } catch (_: EOFException) {
            ResponseStatus.INVALID_REQUEST
        }
        output.writeByte(status.wireValue)
        output.flush()
    }

    private fun processRequest(client: Socket): ResponseStatus {
        if (!TAILSCALE_IPV4_PREFIX.contains(client.inetAddress)) {
            return ResponseStatus.UNAUTHORIZED
        }

        val input = DataInputStream(client.getInputStream())
        val magic = ByteArray(MAGIC.size).also(input::readFully)
        val token = ByteArray(TOKEN_BYTES).also(input::readFully)
        val expectedToken = readExpectedToken() ?: return ResponseStatus.UNAUTHORIZED
        if (!magic.contentEquals(MAGIC) || !MessageDigest.isEqual(token, expectedToken)) {
            return ResponseStatus.UNAUTHORIZED
        }

        val uriLength = input.readUnsignedShort()
        if (uriLength == 0 || uriLength > MAX_URI_BYTES) {
            return ResponseStatus.INVALID_REQUEST
        }

        val uriBytes = ByteArray(uriLength).also(input::readFully)
        val uri = parseFidoUri(String(uriBytes, Charsets.US_ASCII))
            ?: return ResponseStatus.INVALID_REQUEST
        return openFidoUri(uri)
    }

    private fun openFidoUri(uri: Uri): ResponseStatus {
        if (!Settings.canDrawOverlays(this)) {
            updateNotification(R.string.notification_permission_required)
            return ResponseStatus.PERMISSION_REQUIRED
        }

        return try {
            startActivity(
                Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            updateNotification(R.string.notification_prompt_opened)
            ResponseStatus.OK
        } catch (exception: ActivityNotFoundException) {
            logOpenFailure(exception)
        } catch (exception: SecurityException) {
            logOpenFailure(exception)
        }
    }

    private fun readExpectedToken(): ByteArray? = try {
        Base64.getDecoder()
            .decode(File(filesDir, TOKEN_FILENAME).readText().trim())
            .takeIf { it.size == TOKEN_BYTES }
    } catch (exception: IOException) {
        Log.e(TAG, "Shared token is unavailable", exception)
        null
    } catch (exception: IllegalArgumentException) {
        Log.e(TAG, "Shared token is invalid", exception)
        null
    }

    private fun logOpenFailure(exception: RuntimeException): ResponseStatus {
        Log.e(TAG, "Could not open FIDO URI", exception)
        return ResponseStatus.NO_HANDLER
    }

    private fun parseFidoUri(value: String): Uri? {
        if (value.length > MAX_URI_BYTES) return null

        return Uri.parse(value).takeIf { uri ->
            uri.scheme == FIDO_SCHEME &&
                uri.encodedAuthority == null &&
                uri.encodedQuery == null &&
                uri.encodedFragment == null &&
                uri.encodedPath?.matches(FIDO_PATH) == true
        }
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.notification_channel_description)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun createNotification(textResource: Int): Notification {
        val activityIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            activityIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(getString(textResource))
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(textResource: Int) {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, createNotification(textResource))
    }

    private fun closeServerSocket() {
        try {
            serverSocket?.close()
        } catch (exception: IOException) {
            Log.w(TAG, "Could not close passkey listener", exception)
        }
    }

    private enum class ResponseStatus(val wireValue: Int) {
        OK(0),
        UNAUTHORIZED(1),
        INVALID_REQUEST(2),
        PERMISSION_REQUIRED(3),
        NO_HANDLER(4),
    }

    companion object {
        private const val TAG = "FidoPhone"
        private const val CHANNEL_ID = "passkey_bridge"
        private const val NOTIFICATION_ID = 1
        private const val PORT = 48_124
        private const val LISTEN_BACKLOG = 4
        private const val CLIENT_TIMEOUT_MILLIS = 5_000
        private const val MAX_URI_BYTES = 2_048
        private const val TOKEN_BYTES = 32
        private const val TOKEN_FILENAME = "fido-token"
        private const val FIDO_SCHEME = "FIDO"

        private val MAGIC = "FIDOPHN1".toByteArray(Charsets.US_ASCII)
        private val TAILSCALE_IPV4_PREFIX = IpPrefix(
            InetAddresses.parseNumericAddress("100.64.0.0"),
            10,
        )
        private val FIDO_PATH = Regex("/[0-9]{32,}")

        fun start(context: Context) {
            context.startForegroundService(Intent(context, PasskeyBridgeService::class.java))
        }
    }
}
