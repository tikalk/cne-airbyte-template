import json
import os
import re
from dataclasses import dataclass
from typing import Any, Dict, Optional

import requests


def _expand_env_placeholders(obj: Any) -> Any:
    if isinstance(obj, str):
        # Replace ${VAR} with env var values
        pattern = re.compile(r"\$\{([A-Z0-9_]+)\}")
        def repl(match):
            var = match.group(1)
            return os.environ.get(var, "")
        return pattern.sub(repl, obj)
    if isinstance(obj, list):
        return [_expand_env_placeholders(v) for v in obj]
    if isinstance(obj, dict):
        return {k: _expand_env_placeholders(v) for k, v in obj.items()}
    return obj


@dataclass
class AirbyteClient:
    base_url: str
    username: Optional[str] = None
    password: Optional[str] = None

    def __post_init__(self):
        self.session = requests.Session()
        if self.username and self.password:
            self.session.auth = (self.username, self.password)
        self.session.headers.update({"Content-Type": "application/json"})

    # -------- workspace --------
    def get_default_workspace_id(self) -> str:
        resp = self.session.post(
            f"{self.base_url}/api/v1/workspaces/list",
            data=json.dumps({})
        )
        resp.raise_for_status()
        workspaces = resp.json().get("workspaces", [])
        if not workspaces:
            raise RuntimeError("No Airbyte workspaces found")
        # Prefer the one flagged as default, else take first
        for w in workspaces:
            if w.get("displayName") == "Default Workspace" or w.get("defaultWorkspace", False):
                return w["workspaceId"]
        return workspaces[0]["workspaceId"]

    # -------- definitions lookup --------
    def _find_source_definition_id(self, name: str) -> str:
        resp = self.session.post(
            f"{self.base_url}/api/v1/source_definitions/list",
            data=json.dumps({})
        )
        resp.raise_for_status()
        for d in resp.json().get("sourceDefinitions", []):
            if d.get("name") == name:
                return d["sourceDefinitionId"]
        raise RuntimeError(f"Source definition '{name}' not found. Is the connector available?")

    def _find_destination_definition_id(self, name: str) -> str:
        resp = self.session.post(
            f"{self.base_url}/api/v1/destination_definitions/list",
            data=json.dumps({})
        )
        resp.raise_for_status()
        for d in resp.json().get("destinationDefinitions", []):
            if d.get("name") == name:
                return d["destinationDefinitionId"]
        raise RuntimeError(f"Destination definition '{name}' not found. Is the connector available?")

    # -------- helpers --------
    def _list_sources(self, workspace_id: str) -> Dict[str, Any]:
        resp = self.session.post(
            f"{self.base_url}/api/v1/sources/list",
            data=json.dumps({"workspaceId": workspace_id})
        )
        resp.raise_for_status()
        return resp.json()

    def _list_destinations(self, workspace_id: str) -> Dict[str, Any]:
        resp = self.session.post(
            f"{self.base_url}/api/v1/destinations/list",
            data=json.dumps({"workspaceId": workspace_id})
        )
        resp.raise_for_status()
        return resp.json()

    # -------- upsert source --------
    def upsert_source(self, workspace_id: str, name: str, definition_name: str, configuration: Dict[str, Any]) -> str:
        configuration = _expand_env_placeholders(configuration)
        # see if exists
        existing = self._list_sources(workspace_id).get("sources", [])
        for s in existing:
            if s.get("name") == name:
                source_id = s["sourceId"]
                payload = {
                    "sourceId": source_id,
                    "connectionConfiguration": configuration
                }
                resp = self.session.post(
                    f"{self.base_url}/api/v1/sources/update",
                    data=json.dumps(payload)
                )
                resp.raise_for_status()
                return source_id

        definition_id = self._find_source_definition_id(definition_name)
        payload = {
            "workspaceId": workspace_id,
            "name": name,
            "sourceDefinitionId": definition_id,
            "connectionConfiguration": configuration
        }
        resp = self.session.post(
            f"{self.base_url}/api/v1/sources/create",
            data=json.dumps(payload)
        )
        resp.raise_for_status()
        return resp.json()["sourceId"]

    # -------- upsert destination --------
    def upsert_destination(self, workspace_id: str, name: str, definition_name: str, configuration: Dict[str, Any]) -> str:
        configuration = _expand_env_placeholders(configuration)
        existing = self._list_destinations(workspace_id).get("destinations", [])
        for d in existing:
            if d.get("name") == name:
                destination_id = d["destinationId"]
                payload = {
                    "destinationId": destination_id,
                    "connectionConfiguration": configuration
                }
                resp = self.session.post(
                    f"{self.base_url}/api/v1/destinations/update",
                    data=json.dumps(payload)
                )
                resp.raise_for_status()
                return destination_id

        definition_id = self._find_destination_definition_id(definition_name)
        payload = {
            "workspaceId": workspace_id,
            "name": name,
            "destinationDefinitionId": definition_id,
            "connectionConfiguration": configuration
        }
        resp = self.session.post(
            f"{self.base_url}/api/v1/destinations/create",
            data=json.dumps(payload)
        )
        resp.raise_for_status()
        return resp.json()["destinationId"]

    # -------- discover catalog --------
    def discover_source_schema(self, source_id: str) -> Dict[str, Any]:
        resp = self.session.post(
            f"{self.base_url}/api/v1/sources/discover_schema",
            data=json.dumps({"sourceId": source_id})
        )
        resp.raise_for_status()
        return resp.json().get("catalog")

    # -------- upsert connection --------
    def list_connections_for_workspace(self, workspace_id: str) -> Dict[str, Any]:
        resp = self.session.post(
            f"{self.base_url}/api/v1/connections/list",
            data=json.dumps({"workspaceId": workspace_id})
        )
        resp.raise_for_status()
        return resp.json()

    def list_connections_all(self) -> Dict[str, Any]:
        resp = self.session.post(
            f"{self.base_url}/api/v1/connections/list_all",
            data=json.dumps({})
        )
        resp.raise_for_status()
        return resp.json()

    def upsert_connection(
        self,
        name: str,
        source_id: str,
        destination_id: str,
        catalog: Dict[str, Any],
        prefix: Optional[str],
        schedule: Dict[str, Any],
        namespace_definition: str,
        namespace_format: Optional[str],
        sync_mode: str,
        destination_sync_mode: str,
        normalize: bool,
        status: str = "active",
    ) -> str:
        # Build configured catalog: select all streams with provided modes
        configured_streams = []
        for s in catalog.get("streams", []):
            supported_sync_modes = s.get("supportedSyncModes", ["full_refresh"])
            mode = sync_mode if sync_mode in supported_sync_modes else supported_sync_modes[0]
            dest_sync_mode = destination_sync_mode
            configured_streams.append({
                "stream": s,
                "syncMode": mode,
                "destinationSyncMode": dest_sync_mode,
                "cursorField": s.get("defaultCursorField", []),
                "primaryKey": s.get("sourceDefinedPrimaryKey", []),
            })

        configured_catalog = {"streams": configured_streams}

        # Try update by name if exists
        # Try list_all (works across workspaces). Fallback to empty if not supported
        try:
            existing = self.list_connections_all().get("connections", [])
        except requests.HTTPError:
            existing = []
        connection_id = None
        for c in existing:
            if c.get("name") == name:
                connection_id = c["connectionId"]
                break

        payload_common = {
            "name": name,
            "sourceId": source_id,
            "destinationId": destination_id,
            "namespaceDefinition": namespace_definition,
            "namespaceFormat": namespace_format,
            "prefix": prefix or "",
            "scheduleType": schedule.get("type"),
            "scheduleData": {
                "basicSchedule": schedule.get("basic_schedule"),
                "cron": schedule.get("cron"),
            },
            "syncCatalog": configured_catalog,
            "status": status,
            "geography": "AUTO",
        }

        if connection_id:
            payload = {"connectionId": connection_id, **payload_common}
            resp = self.session.post(
                f"{self.base_url}/api/v1/connections/update",
                data=json.dumps(payload)
            )
            resp.raise_for_status()
            return connection_id

        resp = self.session.post(
            f"{self.base_url}/api/v1/connections/create",
            data=json.dumps(payload_common)
        )
        resp.raise_for_status()
        return resp.json()["connectionId"]

    # -------- utility --------
    @staticmethod
    def load_json_file(path: str) -> Dict[str, Any]:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)

    @staticmethod
    def load_yaml_file(path: str) -> Dict[str, Any]:
        import yaml
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)


