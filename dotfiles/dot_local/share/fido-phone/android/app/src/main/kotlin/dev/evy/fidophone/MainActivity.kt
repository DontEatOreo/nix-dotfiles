package dev.evy.fidophone

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.widget.TextView

class MainActivity : Activity() {
    private lateinit var statusView: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        statusView = requireViewById(R.id.status)
        requireViewById<View>(R.id.allow_overlay).setOnClickListener { openOverlaySettings() }
        requireViewById<View>(R.id.start_receiver).setOnClickListener {
            PasskeyBridgeService.start(this)
            updateStatus()
        }
        requestNotificationPermission()
    }

    override fun onResume() {
        super.onResume()
        updateStatus()
        if (Settings.canDrawOverlays(this)) {
            PasskeyBridgeService.start(this)
        }
    }

    private fun openOverlaySettings() {
        startActivity(
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.fromParts("package", packageName, null),
            ),
        )
    }

    private fun requestNotificationPermission() {
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST,
            )
        }
    }

    private fun updateStatus() {
        statusView.setText(
            if (Settings.canDrawOverlays(this)) {
                R.string.status_ready
            } else {
                R.string.status_permission_required
            },
        )
    }

    private companion object {
        const val NOTIFICATION_PERMISSION_REQUEST = 1
    }
}
