#!/bin/bash

opam exec -- forester build forest.toml

rm -rf docs/*

mv -f output/* docs

rm -rf output
