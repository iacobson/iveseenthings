defmodule ISTWeb.PageController do
  use ISTWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
