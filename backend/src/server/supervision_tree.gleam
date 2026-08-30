import gleam/http/request
import gleam/http/response
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import mist
import pog
import wisp
import wisp/wisp_mist

type Request =
  request.Request(wisp.Connection)

type Response =
  response.Response(wisp.Body)

pub fn start(
  http_handler: fn(Request) -> Response,
  database_config: pog.Config,
  secret_key: String,
) -> Result(actor.Started(supervisor.Supervisor), actor.StartError) {
  let http_server =
    wisp_mist.handler(http_handler, secret_key)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)

  supervisor.new(supervisor.OneForOne)
  |> supervisor.add(mist.supervised(http_server))
  |> supervisor.add(pog.supervised(database_config))
  |> supervisor.start
}
