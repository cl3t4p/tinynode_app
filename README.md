# TinyNode

TinyNode is a lightweight Flutter application designed for controlling IoT relay devices via REST API. It features a modular button system, drag-and-drop reordering, and automatic theme synchronization.

## Features

* **REST Integration**: Communicates with devices via POST requests using Bearer Token authentication.
* **Modify Mode**: A dedicated edit state to add, edit, or delete buttons without accidental triggers.
* **Reorderable UI**: Organize your control dashboard using drag-and-drop.
* **Automatic Dark Mode**: System-level theme detection for high-contrast or low-light environments.
* **Persistent Storage**: Saves server configurations and button layouts locally using shared_preferences.

## API Specification

The application sends a JSON payload to the following dynamic endpoint:  
`POST {server_url}/device/{device_id}/relay`

**Headers:**
* `Authorization: Bearer {api_key}`
* `Content-Type: application/json`

**Payload:**
```json
{
  "state": 1,
  "port": 16
}