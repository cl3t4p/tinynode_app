# TinyNode Mobile

TinyNode Mobile is a Flutter-based client application used to control TinyNode-enabled IoT devices through a REST API.  
It is designed to be simple, fast, and fully local-network friendly, while also supporting remote deployments.

The app sends HTTPS commands to a TinyNode backend, which then relays actions to devices via MQTT.

---

## Architecture

```
TinyNode Mobile (Flutter)
        |
        | HTTP (Bearer Authentication)
        v
TinyNode Server (Rust / Axum)
        |
        | MQTT
        v
ESP32 Devices
```

---

## Configuration

All configuration is done directly inside the app through the Settings screen.

### Required settings

- **Server URL**  
  Example:
  ```
  http://192.168.1.100:7538
  ```
  or
  ```
  https://tinynode.example.com
  ```

- **API Token (Bearer)**  
  Must match the `API_TOKEN` configured on the TinyNode server.

### Optional settings

- Username
- Password  
  (Currently stored but not required unless backend logic uses them.)

---

## API Interaction

### HTTP Endpoint

```
POST /device/{device_id}/relay
```

### Headers

```
Authorization: Bearer <API_TOKEN>
Content-Type: application/json
```

### Request Body

```json
{
  "state": 1,
  "port": 16
}
```

- `state`: Integer command value (e.g. 0 = off, 1 = on, 2 = timed)
- `port`: Relay or GPIO port number

---

## Local Storage

The application stores the following data locally using SharedPreferences:

- Server URL
- API token
- Optional username and password
- Configured action buttons

No data is transmitted except the explicit HTTP requests sent to the configured server.

---

## Android Notes

- Internet access requires the following permissions:
  ```
  android.permission.INTERNET
  android.permission.ACCESS_NETWORK_STATE
  ```

- `127.0.0.1` refers to the Android device itself.  
  Use a LAN IP or domain name to reach the TinyNode server.

---

## Development

Run locally:
```
flutter pub get
flutter run
```

Build Android APK:
```
flutter build apk
```

Build App Bundle (Play Store):
```
flutter build appbundle
```

---

## Related Projects
- [TinyNode Server (Rust / Axum)](https://github.com/cl3t4p/tinynode_server).
- [ESP32 TinyNode Firmware](https://github.com/cl3t4p/tinynode_esp32).