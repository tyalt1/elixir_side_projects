# LiveviewExample

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## LiveView

Most of this code was made with `phx.new`. Only 2 files were changed/added.

Added this line `lib/liveview_example_web/router.ex`
```elixir
live "/counter", Counter
```

Added `lib/liveview_example_web/live/counter.ex`
