## Airbyte template: S3 → BigQuery (extensible)

This repository is a clean, extensible scaffold for managing Airbyte configurations as code. It includes:

- A runnable, idempotent Python script that provisions an S3 source, a BigQuery destination, and a connection between them using the Airbyte API
- Clear directory layout to add more sources, destinations, and connections
- Environment-driven configuration and secret handling

You can run against a local Airbyte OSS instance (default) or any reachable Airbyte API endpoint.

### Prerequisites

- Docker (only if you need to run Airbyte locally). Follow Airbyte OSS quickstart from their docs to start the platform
- Python 3.9+
- An Airbyte instance URL (default `http://localhost:8000`)
- AWS credentials with read access to your S3 bucket
- GCP service account with BigQuery permissions and a JSON key file

### Repo structure

```
.
├── resources/
│   ├── connections/
│   │   └── s3_to_bigquery.yaml           # connection settings (name, schedule, etc.)
│   ├── destinations/
│   │   └── bigquery.json                 # destination config template (env-driven)
│   └── sources/
│       └── s3_to_bigquery.json           # source config template (env-driven)
├── scripts/
│   ├── airbyte_api.py                    # tiny API client wrapper
│   └── s3_to_bigquery.py                 # example: provisions S3 → BigQuery
├── .env.example
├── Makefile
├── requirements.txt
└── README.md
```

Add more pipelines by copying the files in `resources/{sources,destinations,connections}` and a small provisioning script like `scripts/s3_to_bigquery.py` (you can also generalize it to loop over folders).

### Quickstart (S3 → BigQuery example)

1) Clone and set environment

```
cp .env.example .env
# edit .env with your values
```

2) Prepare Python environment

```
make install
```

3) Fill config templates

- `resources/sources/s3_to_bigquery.json`: S3 bucket name/region/path and file format
- `resources/destinations/bigquery.json`: GCP project/dataset and the path to your service account key file (script will inline its JSON)
- `resources/connections/s3_to_bigquery.yaml`: connection name, schedule, and optional table prefix

4) Ensure Airbyte is running and reachable

- Default API base URL: `http://localhost:8000` (configurable via `AIRBYTE_URL`)
- To run Airbyte locally, follow the official quickstart. Once the web UI is up on port 8000, the API is ready

5) Provision S3 → BigQuery

```
make s3_to_bigquery
```

The script will:

- Resolve the default workspace
- Upsert an S3 source and a BigQuery destination using your configs
- Discover the catalog from the source
- Create or update a connection that syncs all discovered streams using Full Refresh → Overwrite (default)

### Add more sources/destinations/connections

- Copy the example files in `resources/` and adjust names/config
- Duplicate `scripts/s3_to_bigquery.py` and adapt the file paths and connection parameters
- Optionally, centralize multiple pipeline applies into one script that scans `resources/` and applies all

### Configuration and secrets

- Put non-secret defaults in `.env`
- Point `GCP_SA_KEY_PATH` to a local JSON file; the script reads it and inlines the JSON into the destination config payload so you never commit secrets
- You can also set any config values directly in the `.json` files using environment variables (the script will expand `${VAR}` placeholders)

### Notes

- The example uses the built-in Airbyte definitions named "S3" and "BigQuery" and looks them up dynamically
- The connection is created with a manual schedule by default; you can set a basic schedule in `resources/connections/s3_to_bigquery.yaml`


