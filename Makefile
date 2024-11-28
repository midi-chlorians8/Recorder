SHELL := /bin/bash # Use bash syntax instead of default shell
include .env
include .env.override

py_env_dir=.venv
py_sources ?= services/
py_services_dir=services/romalab
py_services= \
	recorder


git-setup-hooks:
	git config core.hooksPath tools/hooks

.env.override:
	@ls .env.override || \
	echo "# Local gitignored file with .env overrides" >> .env.override; \
	echo "Initial .env.override file created"

# Prepare to work with local develop and compose
pip-compile:
	source ${py_env_dir}/bin/activate; \
	for py_service in ${py_services}; do \
		pip-compile \
			--verbose \
			--output-file=${py_services_dir}/$${py_service}/requirements.txt \
			${py_services_dir}/$${py_service}/requirements.in.txt; \
	done;
	@echo "✅ requirements files for production generated. Please commit all requirements changes"
# Prepare to work with local develop and compose

# To local develop
py-env-create:
	python3 -m venv ${py_env_dir}; \
	source ${py_env_dir}/bin/activate; \
	pip install pip-tools

pip-install-dev:
	# The order of installation is important: dev dependencies should be installed first
	# to avoid overwriting specific versions required by each service.
	# Installing service dependencies last ensures they are the final versions in the environment.
	source ${py_env_dir}/bin/activate; \
	pip install -r services/requirements.dev.txt; \
	for py_service in ${py_services}; do \
		pip install -r ${py_services_dir}/$${py_service}/requirements.txt; \
	done;
	@echo "✅ PIP Dependencies for all services + DEV dependencies installed to ${py_env_dir}"
# To local develop


backend-all-start: .env.override
	docker compose --profile="*" up --build --remove-orphans -d

backend-all-down:
	@echo "Stopping & removing all containers and volumes. Database data will be lost too 🚮 ..."
	docker compose  --profile="*" down --remove-orphans --volumes

portal-start:
	docker compose up --build --remove-orphans portal -d



#
# lint & test commands
#

py-mypy:
	source ${py_env_dir}/bin/activate; \
	mypy ${MYPY_EXTRA_OPTIONS} ${py_sources}

ruff-check:
	source ${py_env_dir}/bin/activate; \
	ruff check ${py_sources}

py-black:
	source ${py_env_dir}/bin/activate; \
	black --check ${py_sources}

py-test:
	source ${py_env_dir}/bin/activate; \
	pytest services/

py-pre-push: py-mypy ruff-check py-black py-test
