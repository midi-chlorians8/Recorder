ARG PYTHON_IMAGE=python:3.10.9-slim-bullseye
ARG VENV_DIR=/.venv

FROM ${PYTHON_IMAGE} AS build
ARG VENV_DIR

RUN python -m venv ${VENV_DIR}
ENV PATH="${VENV_DIR}/bin:$PATH"


COPY ./services/nooga/crs_portal/requirements.txt /

RUN --mount=type=cache,target=/pip-cache \
    ls -l /pip-cache; \
    pip install --cache-dir=/pip-cache -r requirements.txt


FROM ${PYTHON_IMAGE}
ARG VENV_DIR
# CRS_VERSION set during build & push phase
# this way the version of the image is always available in container without needing put it in deploy phase
ARG CRS_VERSION
ENV PATH="${VENV_DIR}/bin:$PATH"
ENV CRS_VERSION=${CRS_VERSION}


COPY --from=build ${VENV_DIR} ${VENV_DIR}

RUN mkdir -p /services/nooga
COPY ./services/uvicorn-run.sh /services/
# COPY ./services/nooga/common /services/nooga/common
COPY ./services/nooga/crs_portal /services/nooga/crs_portal
# COPY ./frontend/src/modules/core/i18n/translations frontend/src/modules/core/i18n/translations

CMD ./services/uvicorn-run.sh nooga.crs_portal.main:app --host 0.0.0.0 --port=${CRS_PORTAL_PORT}