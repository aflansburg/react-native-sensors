package com.sensors;

import android.os.Bundle;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.modules.core.DeviceEventManagerModule;


public class Lightsensor extends ReactContextBaseJavaModule implements SensorEventListener {

    private final ReactApplicationContext reactContext;
    private final SensorManager sensorManager;
    private Sensor sensor;
    private double lastReading = (double) System.currentTimeMillis();
    private int interval;
    private Arguments arguments;


    public Lightsensor(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        this.sensorManager = (SensorManager)reactContext.getSystemService(reactContext.SENSOR_SERVICE);
        this.sensor = this.sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT);
    }

    @Override
      public String getName() {
        return "Lightsensor";
      }

    @ReactMethod
    public void isAvailable(Promise promise) {
        if(this.sensor == null) {
            promise.reject(new RuntimeException("No light sensor found"));
            return;
        }

        promise.resolve(null);
    }

    @ReactMethod
    public void startUpdates() {
        sensorManager.registerListener(this, sensor, this.interval * 1000);
    }

    @ReactMethod
    public void stopUpdates() {
        sensorManager.unregisterListener(this);
    }

    @ReactMethod
    public void setUpdateInterval(int updatedInterval) {
        this.interval = updatedInterval;
    }

    // SensorEventListener Interface
    private void sendEvent(String eventName, @Nullable WritableMap params) {
        try {
            this.reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
        } catch (RuntimeException e) {
            Log.e("ERROR", "java.land.RuntimeException : Trying to invoke Javascript before CatalystInstance has been set!");
        }
    }

    @Override
    public void onSensorChanged(SensorEvent sensorEvent) {
        double timestamp = (double) System.currentTimeMillis();

        if(timestamp - lastReading >= interval) {
            lastReading = timestamp;

            sensor = sensorEvent.sensor;
            WritableMap map = Arguments.createMap();

            if(sensor.getType() == Sensor.TYPE_LIGHT) {
                map.putDouble("sensor_value", sensorEvent.values[0]);
                sendEvent("Lightsensor", map);
            }
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {

    }
}