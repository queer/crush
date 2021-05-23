defmodule CrushWeb.Router do
  use CrushWeb, :router

  pipeline :api do
    # plug :accepts, ["json"]
  end

  scope "/", CrushWeb do
    pipe_through :api
    get    "/keys",                     ApiController, :keys
    get    "/:key",                     ApiController, :get
    put    "/:key",                     ApiController, :set
    delete "/:key",                     ApiController, :del
    get    "/:key/:fork",               ApiController, :get
    put    "/:key/:fork",               ApiController, :set
    delete "/:key/:fork",               ApiController, :del

    get    "/:key/info",                ApiController, :key_info
    get    "/:key/:fork/info",          ApiController, :key_info
    post   "/:key/:fork/fork/:target",  ApiController, :fork
    post   "/:key/:fork/merge/:target", ApiController, :merge
  end
end
