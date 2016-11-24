#!/bin/bash

sequel -E -M "$1" -m ./migrations/ "mysql2://tagger:S6L52XKuqR56PGqZujM8z2pr@localhost/tagger"
