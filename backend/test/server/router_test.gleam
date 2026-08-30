import gleam/http
import gleam/list
import server/router
import server_test
import wisp/simulate

pub fn html_document_test() -> Nil {
  use context <- server_test.with_context()
  let endpoint = "/"
  let content_type = "text/html; charset=utf-8"

  let response =
    simulate.browser_request(http.Get, endpoint)
    |> router.handle_request(context)

  assert response.status == 200
  assert list.key_find(response.headers, "content-type") == Ok(content_type)

  Nil
}

pub fn not_found_test() -> Nil {
  use context <- server_test.with_context()
  let endpoint = "/api/healthcheck"

  let response =
    simulate.browser_request(http.Post, endpoint)
    |> router.handle_request(context)

  assert response.status == 404
}

pub fn healthcheck_test() -> Nil {
  use context <- server_test.with_context()
  let endpoint = "/api/healthcheck"

  let response =
    simulate.browser_request(http.Get, endpoint)
    |> router.handle_request(context)

  assert response.status == 200
}
