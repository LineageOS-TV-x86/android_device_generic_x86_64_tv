package org.lineageos.tv.audiooutput;

import android.content.Context;
import android.content.SharedPreferences;
import android.media.AudioAttributes;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.text.TextUtils;
import android.util.Log;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

final class AudioRouteManager {
    private static final String TAG = "AudioOutputSwitch";
    private static final String PREFS = "audio_output_route";
    private static final String KEY_TYPE = "route_type";
    private static final String KEY_ADDRESS = "route_address";
    private static final String KEY_LABEL = "route_label";
    private static final int ROUTE_DEFAULT = -1;
    private static final int ROLE_OUTPUT = 2;
    private static final int TYPE_BUS = 21;
    private static final int TYPE_TELEPHONY = 18;
    private static final int TYPE_USB_HEADSET = 22;

    private AudioRouteManager() {
    }

    static List<RouteItem> getRouteItems(Context context) {
        ArrayList<RouteItem> routes = new ArrayList<RouteItem>();
        routes.add(RouteItem.systemDefault(context.getString(R.string.system_default)));

        AudioManager audioManager = getAudioManager(context);
        if (audioManager == null) {
            return routes;
        }

        Set<String> seen = new HashSet<String>();
        AudioDeviceInfo[] devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS);
        for (AudioDeviceInfo device : devices) {
            if (!isSelectableOutput(device)) {
                continue;
            }
            String address = addressFor(device);
            String key = device.getType() + ":" + address;
            if (seen.add(key)) {
                routes.add(new RouteItem(device, device.getType(), address, labelFor(device)));
            }
        }

        Collections.sort(routes.subList(1, routes.size()), new Comparator<RouteItem>() {
            @Override
            public int compare(RouteItem left, RouteItem right) {
                return left.label.compareToIgnoreCase(right.label);
            }
        });
        return routes;
    }

    static int findSavedRouteIndex(Context context, List<RouteItem> routes) {
        SharedPreferences prefs = prefs(context);
        int type = prefs.getInt(KEY_TYPE, ROUTE_DEFAULT);
        String address = prefs.getString(KEY_ADDRESS, "");
        for (int i = 0; i < routes.size(); i++) {
            RouteItem item = routes.get(i);
            if (type == ROUTE_DEFAULT && item.isDefault()) {
                return i;
            }
            if (!item.isDefault() && item.type == type && TextUtils.equals(item.address, address)) {
                return i;
            }
        }
        return 0;
    }

    static void saveDefaultRoute(Context context) {
        prefs(context).edit()
                .putInt(KEY_TYPE, ROUTE_DEFAULT)
                .putString(KEY_ADDRESS, "")
                .putString(KEY_LABEL, "")
                .apply();
    }

    static void saveRoute(Context context, RouteItem item) {
        prefs(context).edit()
                .putInt(KEY_TYPE, item.type)
                .putString(KEY_ADDRESS, item.address)
                .putString(KEY_LABEL, item.label)
                .apply();
    }

    static RouteResult applySavedRoute(Context context) {
        SharedPreferences prefs = prefs(context);
        int type = prefs.getInt(KEY_TYPE, ROUTE_DEFAULT);
        if (type == ROUTE_DEFAULT) {
            return clearPreferredDeviceForMedia(context);
        }

        String address = prefs.getString(KEY_ADDRESS, "");
        List<RouteItem> routes = getRouteItems(context);
        for (RouteItem item : routes) {
            if (!item.isDefault() && item.type == type && TextUtils.equals(item.address, address)) {
                return setPreferredDeviceForMedia(context, item.device);
            }
        }

        String savedLabel = prefs.getString(KEY_LABEL, context.getString(R.string.unknown_device));
        RouteResult result = clearPreferredDeviceForMedia(context);
        if (result.success) {
            saveDefaultRoute(context);
            return RouteResult.success(context.getString(R.string.status_saved_device_cleared,
                    savedLabel));
        }
        return RouteResult.failure(context.getString(R.string.status_saved_device_missing,
                savedLabel));
    }

    static RouteResult setPreferredDeviceForMedia(Context context, AudioDeviceInfo device) {
        if (device == null) {
            return RouteResult.failure(context.getString(R.string.status_device_unavailable));
        }

        try {
            AudioManager audioManager = getAudioManager(context);
            Object strategy = findMediaProductStrategy();
            Object attributes = createAudioDeviceAttributes(device);
            Method setPreferred = findMethod(
                    AudioManager.class,
                    "setPreferredDeviceForStrategy",
                    strategy.getClass(),
                    attributes.getClass());
            Object result = setPreferred.invoke(audioManager, strategy, attributes);
            if (Boolean.TRUE.equals(result)) {
                return RouteResult.success(context.getString(R.string.status_selected, labelFor(device)));
            }
            return RouteResult.failure(context.getString(R.string.status_route_rejected, labelFor(device)));
        } catch (Throwable e) {
            Log.e(TAG, "Unable to set preferred media output", e);
            return RouteResult.failure(context.getString(R.string.status_route_failed, readableError(e)));
        }
    }

    static RouteResult clearPreferredDeviceForMedia(Context context) {
        try {
            AudioManager audioManager = getAudioManager(context);
            Object strategy = findMediaProductStrategy();
            Method removePreferred = findMethod(
                    AudioManager.class,
                    "removePreferredDeviceForStrategy",
                    strategy.getClass());
            Object result = removePreferred.invoke(audioManager, strategy);
            if (Boolean.TRUE.equals(result)) {
                return RouteResult.success(context.getString(R.string.status_default_selected));
            }
            return RouteResult.failure(context.getString(R.string.status_default_rejected));
        } catch (Throwable e) {
            Log.e(TAG, "Unable to clear preferred media output", e);
            return RouteResult.failure(context.getString(R.string.status_route_failed, readableError(e)));
        }
    }

    private static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    private static AudioManager getAudioManager(Context context) {
        return (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
    }

    private static Object findMediaProductStrategy() throws Exception {
        Class<?> strategyClass = Class.forName("android.media.audiopolicy.AudioProductStrategy");
        Method getStrategies = findMethod(strategyClass, "getAudioProductStrategies");
        Object strategiesObject = getStrategies.invoke(null);
        if (!(strategiesObject instanceof List)) {
            throw new IllegalStateException("Audio product strategies are unavailable");
        }

        AudioAttributes mediaAttributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .build();
        List<?> strategies = (List<?>) strategiesObject;
        for (Object strategy : strategies) {
            Method supports = findMethod(strategy.getClass(), "supportsAudioAttributes",
                    AudioAttributes.class);
            Object supported = supports.invoke(strategy, mediaAttributes);
            if (Boolean.TRUE.equals(supported)) {
                return strategy;
            }
        }

        throw new IllegalStateException("No media audio product strategy found");
    }

    private static Object createAudioDeviceAttributes(AudioDeviceInfo device) throws Exception {
        Class<?> attributesClass = Class.forName("android.media.AudioDeviceAttributes");
        try {
            Constructor<?> constructor = attributesClass.getConstructor(AudioDeviceInfo.class);
            return constructor.newInstance(device);
        } catch (NoSuchMethodException ignored) {
            Constructor<?> constructor = attributesClass.getConstructor(
                    Integer.TYPE, Integer.TYPE, String.class);
            return constructor.newInstance(ROLE_OUTPUT, device.getType(), addressFor(device));
        }
    }

    private static Method findMethod(Class<?> owner, String name, Class<?>... parameterTypes)
            throws NoSuchMethodException {
        try {
            return owner.getMethod(name, parameterTypes);
        } catch (NoSuchMethodException publicMissing) {
            Method method = owner.getDeclaredMethod(name, parameterTypes);
            method.setAccessible(true);
            return method;
        }
    }

    private static boolean isSelectableOutput(AudioDeviceInfo device) {
        if (device == null || !device.isSink()) {
            return false;
        }

        int type = device.getType();
        if (type == TYPE_TELEPHONY || type == TYPE_BUS) {
            return false;
        }

        return true;
    }

    private static String labelFor(AudioDeviceInfo device) {
        String product = safeString(device.getProductName());
        String type = typeLabel(device.getType());
        String address = addressFor(device);

        if (!TextUtils.isEmpty(product) && !TextUtils.equals(product, type)) {
            if (!TextUtils.isEmpty(address)) {
                return product + " (" + type + ", " + address + ")";
            }
            return product + " (" + type + ")";
        }

        if (!TextUtils.isEmpty(address)) {
            return type + " (" + address + ")";
        }
        return type;
    }

    private static String typeLabel(int type) {
        switch (type) {
            case AudioDeviceInfo.TYPE_BUILTIN_SPEAKER:
                return "Built-in speaker";
            case AudioDeviceInfo.TYPE_WIRED_HEADSET:
                return "Wired headset";
            case AudioDeviceInfo.TYPE_WIRED_HEADPHONES:
                return "Wired headphones";
            case AudioDeviceInfo.TYPE_LINE_ANALOG:
                return "Analog line out";
            case AudioDeviceInfo.TYPE_LINE_DIGITAL:
                return "Digital line out";
            case AudioDeviceInfo.TYPE_BLUETOOTH_A2DP:
                return "Bluetooth audio";
            case AudioDeviceInfo.TYPE_HDMI:
                return "HDMI";
            case AudioDeviceInfo.TYPE_HDMI_ARC:
                return "HDMI ARC";
            case AudioDeviceInfo.TYPE_USB_DEVICE:
                return "USB audio";
            case AudioDeviceInfo.TYPE_USB_ACCESSORY:
                return "USB accessory";
            case AudioDeviceInfo.TYPE_DOCK:
                return "Dock";
            case AudioDeviceInfo.TYPE_FM:
                return "FM";
            case AudioDeviceInfo.TYPE_AUX_LINE:
                return "Aux line";
            case TYPE_USB_HEADSET:
                return "USB headset";
            case TYPE_TELEPHONY:
                return "Telephony route";
            case TYPE_BUS:
                return "Audio bus";
            default:
                return "Audio device " + type;
        }
    }

    private static String safeString(CharSequence value) {
        return value == null ? "" : value.toString();
    }

    private static String addressFor(AudioDeviceInfo device) {
        try {
            Method method = findMethod(device.getClass(), "getAddress");
            Object address = method.invoke(device);
            return address == null ? "" : address.toString();
        } catch (Throwable ignored) {
            return "";
        }
    }

    private static String readableError(Throwable throwable) {
        Throwable current = throwable;
        if (current instanceof InvocationTargetException
                && ((InvocationTargetException) current).getTargetException() != null) {
            current = ((InvocationTargetException) current).getTargetException();
        }
        String message = current.getMessage();
        if (!TextUtils.isEmpty(message)) {
            return current.getClass().getSimpleName() + ": " + message;
        }
        return current.getClass().getSimpleName();
    }

    static final class RouteItem {
        final AudioDeviceInfo device;
        final int type;
        final String address;
        final String label;

        static RouteItem systemDefault(String label) {
            return new RouteItem(null, ROUTE_DEFAULT, "", label);
        }

        RouteItem(AudioDeviceInfo device, int type, String address, String label) {
            this.device = device;
            this.type = type;
            this.address = address;
            this.label = label;
        }

        boolean isDefault() {
            return type == ROUTE_DEFAULT;
        }

        @Override
        public String toString() {
            return label;
        }
    }

    static final class RouteResult {
        final boolean success;
        final String message;

        static RouteResult success(String message) {
            return new RouteResult(true, message);
        }

        static RouteResult failure(String message) {
            return new RouteResult(false, message);
        }

        private RouteResult(boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }
}
