package org.lineageos.tv.audiooutput;

import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothClass;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.content.Intent;
import android.net.wifi.WifiManager;
import android.os.IBinder;
import android.util.Log;

import java.lang.reflect.Method;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public final class BootMaintenanceService extends Service {
    private static final String TAG = "AudioOutputSwitch";
    private static final int HID_HOST_PROFILE = 4;
    private static final int CONNECTION_POLICY_ALLOWED = 100;
    private static final int MAX_ATTEMPTS = 8;
    private static final long RETRY_DELAY_MS = 7500;
    private static volatile boolean sRunning;

    @Override
    public int onStartCommand(Intent intent, int flags, final int startId) {
        synchronized (BootMaintenanceService.class) {
            if (sRunning) {
                stopSelf(startId);
                return START_NOT_STICKY;
            }
            sRunning = true;
        }

        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    runMaintenanceLoop();
                } finally {
                    synchronized (BootMaintenanceService.class) {
                        sRunning = false;
                    }
                    stopSelf(startId);
                }
            }
        }, "AudioOutputBootMaintenance").start();

        return START_NOT_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void runMaintenanceLoop() {
        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            if (attempt > 0) {
                sleep(RETRY_DELAY_MS);
            }
            applySavedAudioRoute();
            kickWifiReconnect();
            kickBluetoothHidReconnect();
        }
    }

    private void applySavedAudioRoute() {
        AudioRouteManager.RouteResult result = AudioRouteManager.applySavedRoute(this);
        if (!result.success) {
            Log.w(TAG, result.message);
        }
    }

    private void kickWifiReconnect() {
        try {
            WifiManager wifiManager = (WifiManager) getApplicationContext()
                    .getSystemService(Context.WIFI_SERVICE);
            if (wifiManager == null) {
                return;
            }
            if (!wifiManager.isWifiEnabled()) {
                Log.i(TAG, "Enabling Wi-Fi for saved-network reconnect");
                wifiManager.setWifiEnabled(true);
                return;
            }
            Log.i(TAG, "Requesting Wi-Fi saved-network reconnect");
            wifiManager.reconnect();
        } catch (Throwable e) {
            Log.w(TAG, "Unable to request Wi-Fi reconnect", e);
        }
    }

    private void kickBluetoothHidReconnect() {
        final BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
        if (adapter == null) {
            return;
        }

        try {
            if (!adapter.isEnabled()) {
                Log.i(TAG, "Enabling Bluetooth for remote reconnect");
                invokeIfPresent(adapter, "enable");
                return;
            }

            Set<BluetoothDevice> bondedDevices = adapter.getBondedDevices();
            if (bondedDevices == null || bondedDevices.isEmpty()) {
                return;
            }

            connectBondedHidDevices(adapter, bondedDevices);
        } catch (Throwable e) {
            Log.w(TAG, "Unable to request Bluetooth HID reconnect", e);
        }
    }

    private void connectBondedHidDevices(final BluetoothAdapter adapter,
            final Set<BluetoothDevice> bondedDevices) throws InterruptedException {
        final CountDownLatch latch = new CountDownLatch(1);
        final BluetoothProfile[] profileRef = new BluetoothProfile[1];
        BluetoothProfile.ServiceListener listener = new BluetoothProfile.ServiceListener() {
            @Override
            public void onServiceConnected(int profile, BluetoothProfile proxy) {
                profileRef[0] = proxy;
                latch.countDown();
            }

            @Override
            public void onServiceDisconnected(int profile) {
                latch.countDown();
            }
        };

        if (!adapter.getProfileProxy(getApplicationContext(), listener, HID_HOST_PROFILE)) {
            return;
        }

        try {
            if (!latch.await(8, TimeUnit.SECONDS) || profileRef[0] == null) {
                return;
            }
            BluetoothProfile hidProfile = profileRef[0];
            for (BluetoothDevice device : bondedDevices) {
                if (isLikelyInputDevice(device)) {
                    requestHidConnect(hidProfile, device);
                }
            }
        } finally {
            if (profileRef[0] != null) {
                adapter.closeProfileProxy(HID_HOST_PROFILE, profileRef[0]);
            }
        }
    }

    private void requestHidConnect(BluetoothProfile hidProfile, BluetoothDevice device) {
        try {
            invokeIfPresent(hidProfile, "setConnectionPolicy",
                    new Class<?>[] { BluetoothDevice.class, Integer.TYPE },
                    new Object[] { device, Integer.valueOf(CONNECTION_POLICY_ALLOWED) });
            Object result = invokeIfPresent(hidProfile, "connect",
                    new Class<?>[] { BluetoothDevice.class },
                    new Object[] { device });
            Log.i(TAG, "Requested HID reconnect for " + safeName(device) + ": " + result);
        } catch (Throwable e) {
            Log.w(TAG, "Unable to request HID reconnect for " + safeName(device), e);
        }
    }

    private static boolean isLikelyInputDevice(BluetoothDevice device) {
        String name = safeName(device).toLowerCase();
        if ("ar".equals(name) || name.contains("fire") || name.contains("remote")
                || name.contains("keyboard")) {
            return true;
        }

        BluetoothClass bluetoothClass = device.getBluetoothClass();
        return bluetoothClass != null
                && bluetoothClass.getMajorDeviceClass() == BluetoothClass.Device.Major.PERIPHERAL;
    }

    private static String safeName(BluetoothDevice device) {
        try {
            String name = device.getName();
            return name == null ? device.getAddress() : name;
        } catch (Throwable ignored) {
            return "Bluetooth device";
        }
    }

    private static Object invokeIfPresent(Object target, String name) throws Exception {
        return invokeIfPresent(target, name, new Class<?>[0], new Object[0]);
    }

    private static Object invokeIfPresent(Object target, String name, Class<?>[] parameterTypes,
            Object[] args) throws Exception {
        Method method;
        try {
            method = target.getClass().getMethod(name, parameterTypes);
        } catch (NoSuchMethodException missingPublic) {
            method = target.getClass().getDeclaredMethod(name, parameterTypes);
            method.setAccessible(true);
        }
        return method.invoke(target, args);
    }

    private static void sleep(long delayMs) {
        try {
            Thread.sleep(delayMs);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
