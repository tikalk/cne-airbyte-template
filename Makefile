PY ?= python3
PIP ?= pip3

.PHONY: install s3_to_bigquery

install:
	$(PIP) install -r requirements.txt

s3_to_bigquery:
	$(PY) scripts/s3_to_bigquery.py


