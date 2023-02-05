defmodule ISTWeb.Router do
  use ISTWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ISTWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :basic do
    plug :basic_auth_setup
  end

  live_session :user, on_mount: {ISTWeb.Hook.User, :user_status} do
    scope "/", ISTWeb.Live do
      pipe_through [:browser]

      live "/", Game, :new
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ISTWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through :browser
    pipe_through :basic

    live_dashboard "/dashboard", metrics: ISTWeb.Telemetry
  end

  # Runtime basic auth
  def basic_auth_setup(conn, _opts) do
    username = Application.get_env(:iveseenthings, :basic_auth)[:username]
    password = Application.get_env(:iveseenthings, :basic_auth)[:password]

    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
