#!/usr/bin/env python3
import json
import os
from pathlib import Path

from dotenv import load_dotenv

from scripts.airbyte_api import AirbyteClient


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def ensure_gcp_sa_json_export() -> None:
    key_path = env("GCP_SA_KEY_PATH")
    if not key_path:
        return
    p = Path(key_path)
    if p.exists():
        with p.open("r", encoding="utf-8") as f:
            os.environ["GCP_SA_KEY_JSON"] = f.read()


def main() -> None:
    load_dotenv()
    ensure_gcp_sa_json_export()

    base_url = env("AIRBYTE_URL", "http://localhost:8000")
    username = env("AIRBYTE_USERNAME") or None
    password = env("AIRBYTE_PASSWORD") or None

    client = AirbyteClient(base_url=base_url, username=username, password=password)
    workspace_id = client.get_default_workspace_id()

    # Load source config
    source_cfg = client.load_json_file("resources/sources/s3_to_bigquery.json")
    s_name = source_cfg["name"]
    s_def = source_cfg["definition_name"]
    s_conf = source_cfg["configuration"]
    source_id = client.upsert_source(workspace_id, s_name, s_def, s_conf)

    # Load destination config
    dest_cfg = client.load_json_file("resources/destinations/bigquery.json")
    d_name = dest_cfg["name"]
    d_def = dest_cfg["definition_name"]
    d_conf = dest_cfg["configuration"]
    destination_id = client.upsert_destination(workspace_id, d_name, d_def, d_conf)

    # Discover source catalog
    catalog = client.discover_source_schema(source_id)

    # Load connection settings
    conn_cfg = client.load_yaml_file("resources/connections/s3_to_bigquery.yaml")

    schedule = {
        "type": conn_cfg.get("schedule", {}).get("type", "manual"),
        "basic_schedule": conn_cfg.get("schedule", {}).get("basic_schedule"),
        "cron": conn_cfg.get("schedule", {}).get("cron"),
    }

    connection_id = client.upsert_connection(
        name=env("CONNECTION_NAME", conn_cfg.get("name", "s3_to_bigquery")),
        source_id=source_id,
        destination_id=destination_id,
        catalog=catalog,
        prefix=env("CONNECTION_PREFIX", conn_cfg.get("prefix", "")),
        schedule=schedule,
        namespace_definition=conn_cfg.get("namespace_definition", "destination"),
        namespace_format=conn_cfg.get("namespace_format"),
        sync_mode=env("SYNC_MODE", conn_cfg.get("sync_mode", "full_refresh")),
        destination_sync_mode=env("DEST_SYNC_MODE", conn_cfg.get("destination_sync_mode", "overwrite")),
        normalize=bool(conn_cfg.get("normalize", False)),
        status=conn_cfg.get("status", "active"),
    )

    print(json.dumps({
        "workspaceId": workspace_id,
        "sourceId": source_id,
        "destinationId": destination_id,
        "connectionId": connection_id,
    }, indent=2))


if __name__ == "__main__":
    main()


