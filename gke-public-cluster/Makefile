# Copyright 2024
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Make will use bash instead of sh
SHELL := /usr/bin/env bash

.PHONY: help
help:
	@echo 'Usage:'
	@echo '    make create     Create or update resources with Terraform.'
	@echo '    make teardown   Destroy all resources managed by Terraform.'
	@echo '    make validate   Check that installed resources work as expected.'
	@echo '    make lint       Check syntax of all scripts.'
	@echo

.PHONY: lint
lint: check_shell check_shebangs check_python check_golang check_terraform \
	check_docker check_base_files check_headers check_trailing_whitespace

# create/delete/validate is for CICD
.PHONY: create
create:
	@source scripts/create.sh

.PHONY: validate
validate:
	@source scripts/validate.sh

.PHONY: teardown
teardown:
	@source scripts/teardown.sh

# The .PHONY directive tells make that this isn't a real target and so
# the presence of a file named 'check_shell' won't cause this target to stop
# working
.PHONY: check_shell
check_shell:
	@source test/make.sh && check_shell

.PHONY: check_python
check_python:
	@source test/make.sh && check_python

.PHONY: check_golang
check_golang:
	@source test/make.sh && golang

.PHONY: check_terraform
check_terraform:
	@source test/make.sh && check_terraform

.PHONY: check_docker
check_docker:
	@source test/make.sh && docker

.PHONY: check_base_files
check_base_files:
	@source test/make.sh && basefiles

.PHONY: check_shebangs
check_shebangs:
	@source test/make.sh && check_bash

.PHONY: check_trailing_whitespace
check_trailing_whitespace:
	@source test/make.sh && check_trailing_whitespace

.PHONY: check_headers
check_headers:
	@echo "Checking file headers"
	@python3.7 test/verify_boilerplate.py
