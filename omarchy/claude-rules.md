# Omarchy Linux

- Root: run `pkexec <cmd>`. Omarchy's password dialog keeps the password out of the session; never ask for it in chat. Scripts that call `sudo` themselves (`omarchy pkg add`, `install.sh`) need a terminal, so run the underlying command with `pkexec` instead.
