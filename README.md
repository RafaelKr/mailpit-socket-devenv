# Setup

- Install nix + devenv: https://devenv.sh/getting-started/
- Recommended: Setup and configure direnv: https://devenv.sh/automatic-shell-activation/

# Usage

```bash
git clone git@github.com:RafaelKr/mailpit-socket-devenv.git

cd mailpit-socket-devenv

# If you're using direnv
direnv allow
# If you didn't setup direnv
# devenv shell

devenv up
```

Now you should be able to see mailpit running at http://127.0.0.1:8000/mailpit/  
All served via caddy -> mailpit socket

```bash
# In a new shell:
cd mailpit-socket-devenv
bin/console mailer:test test@example.com
```

You should see a new mail which was delivered via the mailpit socket!


