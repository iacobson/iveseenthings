# IST

![ist](./priv/static/images/ist.gif)

## Run the Project Locally

Create a `dev.secret.exs` file in the `config` directory with the following content:

```elixir
import Config
config :iveseenthings, :basic_auth, username: "user", password: "password"
```

This is needed to access the live dashboard locally.

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
