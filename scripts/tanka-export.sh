#!/bin/sh

cd tanka

tk export ../generated/ environments/ \
    --format '{{or env.metadata.labels.export env.spec.namespace  }}/{{.apiVersion}}.{{.kind}}-{{.metadata.name}}' \
    --merge-strategy 'replace-envs' \
    --recursive

cd ..
