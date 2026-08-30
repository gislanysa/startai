import envoy
import filepath
import gleam/erlang/process
import gleam/result
import pog
import server/context
import server/router
import server/supervision_tree
import wisp

pub fn main() -> Nil {
  wisp.configure_logger()

  //   Postgres
  let db_process_name = process.new_name("db_connection_pool")
  let assert Ok(database_url) = envoy.get("DATABASE_URL")
  let assert Ok(pog_config) = pog.url_config(db_process_name, database_url)
  let database = pog.named_connection(db_process_name)

  // others
  let assert Ok(static_directory) = static_directory()
  let assert Ok(secret_key) = envoy.get("SECRET_KEY")
  let context = context.Context(database:, static_directory:)
  let handler = router.handle_request(_, context)

  // start supervision tree
  let assert Ok(_) = supervision_tree.start(handler, pog_config, secret_key)
  process.sleep_forever()
}

pub fn static_directory() -> Result(String, Nil) {
  use priv_directory <- result.map(wisp.priv_directory("server"))
  filepath.join(priv_directory, "static")
}
