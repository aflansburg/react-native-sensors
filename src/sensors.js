import { DeviceEventEmitter } from "react-native";
import * as Rx from "rxjs/Rx";
import RNSensors from "./rnsensors";

function createSensorMonitorCreator(sensorType) {
  function Creator(options = {}) {
    return RNSensors.isAvailable(sensorType).then(() => {
      const { updateInterval = 100 } = options || {}; // time in ms
      let observer;

      // Instanciate observable
      const observable = Rx.Observable.create(obs => {
        observer = obs;

        DeviceEventEmitter.addListener(sensorType, data => {
          observer.next(data);
        });

        // Start the sensor manager
        RNSensors.start(sensorType, updateInterval);
      });

      // Stop the sensor manager
      observable.stop = () => {
        RNSensors.stop(sensorType);
        observer.complete();
      };

      return observable;
    });
  }

  return Creator;
}

// TODO: lazily intialize them (maybe via getter)
const Accelerometer = createSensorMonitorCreator("Accelerometer");
const Gyroscope = createSensorMonitorCreator("Gyroscope");
const Magnetometer = createSensorMonitorCreator("Magnetometer");
const Lightsensor = createSensorMonitorCreator("Lightsensor");

export default {
  Accelerometer,
  Gyroscope,
  Magnetometer,
  Lightsensor
};
