import server/segment
import server_test
import youid/uuid

pub fn register_segment_test() -> Nil {
  use context <- server_test.with_context()
  let name = "tech"
  let description = "modern technology"

  let assert Ok(segment) =
    segment.register(context.database, name:, description:)

  assert segment.name == name
  assert segment.description == description

  Nil
}

pub fn get_segment_test() -> Nil {
  use context <- server_test.with_context()

  let assert Ok(dummy) =
    segment.register(context.database, name: "wibble", description: "wobble")

  let assert Ok(found) = segment.get(context.database, dummy.id)
  assert dummy == found

  Nil
}

pub fn get_missing_segment_test() -> Nil {
  use context <- server_test.with_context()
  let assert Error(segment.NotFound) = segment.get(context.database, uuid.v7())

  Nil
}
