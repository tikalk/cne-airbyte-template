# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is an Airbyte data ingestion template using Terraform to manage infrastructure as code. The repository configures data sources, destinations, and connections in a multi-environment setup (dev/staging/prod).

### Key Components

- **Data Sources**: S3 (AWS) for Comeet recruiting data and tikal-datalake documents
- **Destinations**: BigQuery for data warehousing
- **Connections**: Automated data pipelines between sources and destinations
- **Multi-environment**: Workspace-aware configuration for dev/staging/prod

### Infrastructure Architecture

- **Backend**: Kubernetes state management with "playground" cluster context
- **Provider**: Airbyte provider for resource management
- **Workspaces**: Environment-specific deployments using Terraform workspaces
- **Modules**: Reusable components in `sources/`, `destinations/`, `connections/`

## File Structure

```
├── main.tf                    # Root module with data sources and modules
├── providers.tf              # Terraform and Airbyte provider configuration
├── variables.tf              # Variable definitions for secrets and config
├── locals.tf                 # Complex local values and data source configs
├── locals.{dev,stage,prod}.tf # Environment-specific connection mappings
├── outputs.tf                # Module outputs
├── terraform.tfvars.example  # Template for environment variables
├── source_table_names.json   # BigQuery namespace format mappings
├── backend-config/           # Kubernetes backend configuration
├── sources/                  # Source module definitions
│   ├── s3/, gcs/, mysql/, etc.
├── destinations/             # Destination module definitions
│   ├── bigquery/, milvus/, firestore/
└── connections/              # Connection module definitions
```

## Common Terraform Commands

### Initialization and Planning
```bash
terraform init -backend-config=backend-config/config.k8s.tfbackend
terraform workspace select cne-airbyte-template-{env}  # dev/stage/prod
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Workspace Management
```bash
terraform workspace list
terraform workspace new cne-airbyte-template-dev
terraform workspace select cne-airbyte-template-prod
```

### Targeting Specific Resources
```bash
terraform plan -target=module.bigquery_destination
terraform apply -target=module.s3_source["comeet_all_candidate"]
```

## Environment Configuration

### Required Variables
All variables must be defined in `terraform.tfvars` (see `terraform.tfvars.example`):
- `WORKSPACE_ID`: Airbyte workspace identifier
- `USERNAME`, `PASSWORD`, `SERVER_URL`: Airbyte authentication
- `SERVICE_ACCOUNT_INFO`: GCP service account JSON for BigQuery
- `BIGQUERY_PROJECT_ID`: BigQuery project identifier
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: AWS S3 access for Comeet and datalake

### Workspace-Specific Behavior
The system uses `terraform.workspace` to determine environment:
- Workspace format: `cne-airbyte-template-{env}` where env is dev/stage/prod
- Connection configurations are filtered by environment in locals files
- Resource naming includes environment suffix for clarity

## Data Source Configuration

### S3 Sources  
Currently configured S3 sources in `locals.tf`:

- **comeet_all_candidate**: Recruiting data with detailed CSV schema for candidate information
- **comeet_all_candidate_steps**: Candidate workflow steps with CSV format
- **tikal-datalake-dev**: Unstructured documents including employee markdown files and engineering playbooks in HTML format

All S3 sources support both CSV and unstructured document formats with detailed schema definitions and validation policies.

## BigQuery Destination

- Project-specific dataset creation in `europe-central2`
- Custom namespace formatting using `source_table_names.json`
- Standard insert loading method with 15MB buffer size
- Environment-aware dataset naming based on workspace

## Connection Management

Connections are defined per environment in `locals.{env}.tf` files:
- Source and destination ID references from modules
- Sync modes: `full_refresh_overwrite`, `full_refresh_append`, `incremental_deduped_history`
- Custom namespace formatting for BigQuery table organization
- Manual scheduling (cron can be configured)

## Development Workflow

1. **Environment Setup**: Ensure `terraform.tfvars` contains all required variables
2. **Workspace Selection**: Switch to appropriate workspace for target environment
3. **Module Development**: Create reusable modules in respective directories
4. **Testing**: Use `terraform plan` to validate changes before applying
5. **Deployment**: Apply changes with appropriate targeting for large infrastructures

## Important Notes

- All secrets are managed through Terraform variables, never hardcoded
- Resource naming includes environment context for multi-tenancy
- State is managed in Kubernetes backend for team collaboration
- Module structure allows for easy addition of new source/destination types
- Connection configurations must reference valid source and destination IDs from modules