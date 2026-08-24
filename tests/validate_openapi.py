#!/usr/bin/env python3
"""Lightweight validation for connector/openapi.json without external dependencies."""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OPENAPI_FILE = ROOT / "connector" / "openapi.json"

REQUIRED_OPERATION_IDS = {
    "ListAutomationAccounts",
    "GetAutomationAccount",
    "ListRunbooks",
    "GetRunbook",
    "StartRunbook",
    "ListJobs",
    "GetJob",
    "StopJob",
}


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    sys.exit(1)


def collect_refs(node, refs):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "$ref" and isinstance(value, str):
                refs.add(value)
            else:
                collect_refs(value, refs)
    elif isinstance(node, list):
        for item in node:
            collect_refs(item, refs)


def main() -> None:
    if not OPENAPI_FILE.exists():
        fail(f"Missing file: {OPENAPI_FILE}")

    try:
        spec = json.loads(OPENAPI_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"Invalid JSON: {exc}")

    for key in ("swagger", "info", "host", "basePath", "paths", "parameters", "definitions", "securityDefinitions"):
        if key not in spec:
            fail(f"Missing top-level key: {key}")

    if spec.get("swagger") != "2.0":
        fail("OpenAPI document must be swagger 2.0")

    operation_ids = set()
    path_item_parameters = {}

    for path, path_item in spec["paths"].items():
        if not isinstance(path_item, dict):
            fail(f"Path item must be an object: {path}")

        required_path_params = set(re.findall(r"\{([^}]+)\}", path))
        declared_path_params = set()

        for shared in path_item.get("parameters", []):
            if isinstance(shared, dict):
                if "$ref" in shared:
                    ref_name = shared["$ref"].split("/")[-1]
                    p = spec["parameters"].get(ref_name)
                    if p and p.get("in") == "path":
                        declared_path_params.add(p["name"])
                elif shared.get("in") == "path":
                    declared_path_params.add(shared.get("name"))

        for method, operation in path_item.items():
            if method == "parameters" or method.startswith("x-"):
                continue
            if not isinstance(operation, dict):
                fail(f"Operation must be object: {method.upper()} {path}")

            operation_id = operation.get("operationId")
            if not operation_id:
                fail(f"Missing operationId: {method.upper()} {path}")
            if operation_id in operation_ids:
                fail(f"Duplicate operationId: {operation_id}")
            operation_ids.add(operation_id)

            op_params = set(declared_path_params)
            for p in operation.get("parameters", []):
                if "$ref" in p:
                    ref_name = p["$ref"].split("/")[-1]
                    param_obj = spec["parameters"].get(ref_name)
                    if not param_obj:
                        fail(f"Missing referenced parameter '#/parameters/{ref_name}' in {operation_id}")
                    if param_obj.get("in") == "path":
                        op_params.add(param_obj.get("name"))
                elif p.get("in") == "path":
                    op_params.add(p.get("name"))

            missing = required_path_params - op_params
            if missing:
                fail(f"Operation {operation_id} missing path parameters: {sorted(missing)}")

            path_item_parameters[(path, method)] = op_params

    missing_ops = REQUIRED_OPERATION_IDS - operation_ids
    if missing_ops:
        fail(f"Missing required operations: {sorted(missing_ops)}")

    refs = set()
    collect_refs(spec, refs)

    for ref in refs:
        if ref.startswith("#/definitions/"):
            definition_name = ref.split("/")[-1]
            if definition_name not in spec["definitions"]:
                fail(f"Missing definition reference target: {ref}")
        elif ref.startswith("#/parameters/"):
            parameter_name = ref.split("/")[-1]
            if parameter_name not in spec["parameters"]:
                fail(f"Missing parameter reference target: {ref}")

    print(f"OK: {OPENAPI_FILE} passed lightweight validation.")


if __name__ == "__main__":
    main()
