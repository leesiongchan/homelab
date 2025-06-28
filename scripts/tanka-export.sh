#!/bin/sh

cd tanka

tk export ../generated/ environments/ \
    --format '{{or env.metadata.labels.export env.spec.namespace  }}/{{.metadata.name}}.{{.kind}}' \
    --merge-strategy 'replace-envs' \
    --recursive

cd ..
