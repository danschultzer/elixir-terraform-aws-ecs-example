# MyProject

This is just a skeleton folder for where you would have your Elixir app. Go to [`.infrastructure`][.infrastructure] to see all IaC files.

## Quick start

If you want to get started quickly with a default Phoenix setup then folllow the instructions below. First generate the phoenix app outside the folder:

```bash
mix phx.new my_project
```

Go to the folder and generate the release configuration:

``bash
cd my_project
mix phx.gen.release --docker
```

Move the docker to a `.release` container folder, and generate an the `.release/entrypoint.sh` file:

```
mkdir .release
mv .dockerignore Dockerfile ./.release/
<<'SH' > .release/entrypoint.sh
bin/my_project eval "MyProject.Release.migrate()"
bin/my_project start
SH
```

Now you are ready to deploy to AWS!
