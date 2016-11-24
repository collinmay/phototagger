#!/bin/bash

sequel -E -m ./migrations/ "mysql2://tagger:S6L52XKuqR56PGqZujM8z2pr@localhost/tagger"
sequel -d "mysql2://tagger:S6L52XKuqR56PGqZujM8z2pr@localhost/tagger" > schema.rb
