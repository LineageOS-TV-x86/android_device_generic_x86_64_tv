package org.lineageos.tv.audiooutput;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public final class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "AudioOutputSwitch";
    private static final String ACTION_LOCKED_BOOT_COMPLETED =
            "android.intent.action.LOCKED_BOOT_COMPLETED";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent == null ? null : intent.getAction();
        if (!Intent.ACTION_BOOT_COMPLETED.equals(action)
                && !ACTION_LOCKED_BOOT_COMPLETED.equals(action)) {
            return;
        }

        AudioRouteManager.RouteResult result = AudioRouteManager.applySavedRoute(context);
        if (!result.success) {
            Log.w(TAG, result.message);
        }
    }
}
