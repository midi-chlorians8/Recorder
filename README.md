# Recorder

Recorder project monorepo.
Record online site. People open page and click their personal record

## Development

### Pre-requirements

- Linux(Unix), MacOs
- `python` (see required version in [.python-version](.python-version))
- `make` utility
- `docker and docker compose` https://docs.docker.com/compose/install/

### Setup

```bash
make git-setup-hooks
make py-env-create

# bellow command make possible auto-complete and other IDE feature, like linting code (in git hooks too)
# re-run it each time when pip dependencies change
make pip-install-dev
```


### Run application components

Using make you may run different components in development mode.
See details in `make *-start` commands

```bash
make backend-all-start # run all backend components
#make frontend-start # run frontend in development mode
```

To recreate DB from scratch perform steps

```bash
make backend-all-down
make backend-all-start
```

### Backend

- [./docs/backend.md](./docs/backend.md)

### DevOps

- [./docs/devops.md](./docs/devops.md)


### Database

#### Apply migrations for any database

```bash
make db-apply-alembic-migrations
```

```sh
# Note: result env values will be obtains as merge from .env file and this file
RECORDER_DB_HOST=...
RECORDER_DB_PORT=...
RECORDER_DB_NAME=...
RECORDER_DB_USER=...
RECORDER_DB_PASSWORD=...
```

#### Create user

To login in web application we need create user. Currently we creating him manually using bellow command

```bash
sudo apt install postgresql-client
```

```bash
make db-create-user
```




make git-setup-hooks
make py-env-create
source .venv/bin/activate
./services/uvicorn-run.sh romalab.recorder.main:app --host 0.0.0.0 --port=3100