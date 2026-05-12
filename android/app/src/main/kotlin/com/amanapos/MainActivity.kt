package com.amanapos

import android.os.Build
import android.provider.Settings
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "amana_pos/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceId" -> {
                    result.success(getDeviceInfo())
                }

                "getAppVersion" -> {
                    result.success(getAppVersion())
                }

                "getBuildNumber" -> {
                    result.success(getBuildNumber())
                }

                "getDeviceMeta" -> {
                    result.success(
                        mapOf(
                            "deviceId" to getDeviceInfo(),
                            "appVersion" to getAppVersion(),
                            "buildNumber" to getBuildNumber(),
                            "platform" to "android"
                        )
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getDeviceInfo(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                Build.getSerial()
            } catch (e: SecurityException) {
                getAndroidId()
            } catch (e: Exception) {
                getAndroidId()
            }
        } else {
            @Suppress("DEPRECATION")
            val serial = Build.SERIAL
            if (serial.isNullOrBlank() || serial == Build.UNKNOWN) {
                getAndroidId()
            } else {
                serial
            }
        }
    }

    private fun getAndroidId(): String {
        return try {
            Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ANDROID_ID
            ) ?: ""
        } catch (e: Exception) {
            ""
        }
    }

    private fun getAppVersion(): String {
        return try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }

            packageInfo.versionName ?: ""
        } catch (e: Exception) {
            ""
        }
    }

    private fun getBuildNumber(): String {
        return try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.longVersionCode.toString()
            } else {
                @Suppress("DEPRECATION")
                packageInfo.versionCode.toString()
            }
        } catch (e: Exception) {
            ""
        }
    }
}