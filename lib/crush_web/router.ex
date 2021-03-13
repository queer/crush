defmodule CrushWeb.Router do
  use CrushWeb, :router

  pipeline :api do
    # plug :accepts, ["json"]
  end

  scope "/", CrushWeb do
    pipe_through :api
    get    "/:key", ApiController, :get
    put    "/:key", ApiController, :set
    delete "/:key", ApiController, :del
  end
end
