ARG PYTHON_IMAGE=python:3.10.9-slim-bullseye
ARG VENV_DIR=/.venv

FROM ${PYTHON_IMAGE} AS build
ARG VENV_DIR

RUN python -m venv ${VENV_DIR}
ENV PATH="${VENV_DIR}/bin:$PATH"


COPY ./services/romalab/recorder/requirements.txt /

RUN --mount=type=cache,target=/pip-cache \
    ls -l /pip-cache; \
    pip install --cache-dir=/pip-cache -r requirements.txt


FROM ${PYTHON_IMAGE}
ARG VENV_DIR
# RECORDER_VERSION set during build & push phase
# this way the version of the image is always available in container without needing put it in deploy phase
ARG RECORDER_VERSION
ENV PATH="${VENV_DIR}/bin:$PATH"
ENV RECORDER_VERSION=${RECORDER_VERSION}

COPY --from=build ${VENV_DIR} ${VENV_DIR}

RUN mkdir -p /services/romalab
COPY ./services/uvicorn-run.sh /services/
COPY ./services/romalab/recorder /services/romalab/recorder

CMD ./services/uvicorn-run.sh romalab.recorder.main:app --host 0.0.0.0 --port=${RECORDER_PORT}