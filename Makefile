SHELL := /bin/bash # Use bash syntax instead of default shell

py_env_dir=.venv
py_sources ?= services/
py_services_dir=services/nooga
py_services= \
	crs_portal


git-setup-hooks:
	git config core.hooksPath tools/hooks

py-env-create:
	python3 -m venv ${py_env_dir}
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
