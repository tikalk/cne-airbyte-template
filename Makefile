UV ?= uv

.PHONY: install s3_to_bigquery run lock

install:
	$(UV) sync

s3_to_bigquery:
	$(UV) run scripts/s3_to_bigquery.py

run:
	$(UV) run scripts/s3_to_bigquery.py

lock:
	$(UV) lock


