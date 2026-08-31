import gleam/http
import gleam/http/request
import gleam/http/response
import lustre/attribute
import lustre/element
import lustre/element/html
import server/context
import wisp

pub fn handle_request(
  request: request.Request(wisp.Connection),
  context: context.Context,
) -> response.Response(wisp.Body) {
  use request <- middleware(request, context)
  case request.method, request.path_segments(request) {
    http.Get, [] -> html_document()

    // healthcheck
    http.Get, ["api", "healthcheck"] -> wisp.ok()

    // fallback
    _, _ -> wisp.not_found()
  }
}

fn middleware(
  req: request.Request(wisp.Connection),
  context: context.Context,
  next: fn(request.Request(wisp.Connection)) -> response.Response(wisp.Body),
) -> response.Response(wisp.Body) {
  let request = wisp.method_override(req)
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes()
  use request <- wisp.handle_head(request)
  use request <- wisp.csrf_known_header_protection(request)
  use <- wisp.serve_static(request, "/static", context.static_directory)

  next(request)
}

fn html_document() -> response.Response(wisp.Body) {
  let body =
    html.html([], [
      html.head([], [html.title([], "SENAC")]),
      html.body([], [html.div([attribute.id("app")], [])]),
    ])

  element.to_document_string(body)
  |> wisp.html_body(wisp.ok(), _)
}
