#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
julia "--project=$SCRIPT_DIR" "$SCRIPT_DIR/src/application.jl"