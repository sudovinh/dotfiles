-- Rex config. Managed by chezmoi: edit dot/private_dot_config/rex/init.lua.
-- Migrated from tmux, zellij, Herdr, Ghostty and iTerm2.

-- tmux (~/.tmux.conf), prefix ctrl+a
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
rex.bind("ctrl+a>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+a>-", "pane.split", { direction = "down" })
rex.bind("ctrl+a>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+a>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+a>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+a>l", "pane.focus", { direction = "right" })
rex.bind("ctrl+a>r", "client.config.reload")

-- iTerm2 (GlobalKeyMap): shift+enter sends a newline
rex.bind("shift+enter", "pane.send_key", { key = "ctrl+j" })
