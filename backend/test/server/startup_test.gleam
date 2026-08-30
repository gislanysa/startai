import gleam/int
import gleam/list
import gleam/result
import gleam/set
import server/segment
import server/startup
import server/user
import server_test
import wisp
import youid/uuid

pub fn register_startup_test() -> Nil {
  use context <- server_test.with_context()

  let assert Ok(segment) =
    segment.register(context.database, "gaming", "videogames are cool")

  let name = "Critic Level"
  let cnpj = "12345678901234"
  let description = "startup muito maneira"
  let city = "Recife"
  let state = "Pernambuco"

  let assert Ok(startup) =
    startup.register(
      context.database,
      segment.id,
      name,
      cnpj,
      description,
      city,
      state,
    )

  assert startup.name == name
  assert startup.cnpj == cnpj
  assert startup.description == description
  assert startup.city == city
  assert startup.state == state

  Nil
}

pub fn register_invalid_cnpj_test() -> Nil {
  use context <- server_test.with_context()

  let assert Ok(segment) =
    segment.register(context.database, "gaming", "videogames are cool")

  let assert Error(startup.InvalidCnpjFormat) =
    startup.register(context.database, segment.id, "", "invalid", "", "", "")

  Nil
}

pub fn register_cnpj_conflict_test() -> Nil {
  use context <- server_test.with_context()

  let assert Ok(segment) =
    segment.register(context.database, "gaming", "videogames are cool")

  let assert Ok(_startup) =
    startup.register(
      context.database,
      segment_id: segment.id,
      name: "",
      cnpj: "12345678912345",
      description: "",
      city: "",
      state: "",
    )

  let assert Error(startup.CnpjConflict) =
    startup.register(
      context.database,
      segment_id: segment.id,
      name: "",
      cnpj: "12345678912345",
      description: "",
      city: "",
      state: "",
    )

  Nil
}

pub fn get_startup_test() -> Nil {
  use context <- server_test.with_context()

  let assert Ok(segment) =
    segment.register(context.database, "gaming", "videogames are cool")

  let assert Ok(dummy) =
    startup.register(
      context.database,
      segment.id,
      "Critic Level",
      "12345678901234",
      "startup muito maneira",
      "Recife",
      "Pernambuco",
    )

  let assert Ok(found) = startup.get(context.database, dummy.id)
  assert found == dummy

  Nil
}

pub fn get_missing_startup_test() -> Nil {
  use context <- server_test.with_context()
  let assert Error(startup.NotFound) = startup.get(context.database, uuid.v7())

  Nil
}

pub fn assign_startup_members_test() -> Nil {
  use context <- server_test.with_context()

  let assert Ok(segment) = segment.register(context.database, "", "")

  let cnpj = wisp.random_string(14)
  let assert Ok(startup) =
    startup.register(context.database, segment.id, "", cnpj, "", "", "")

  let members = {
    use acc, i <- int.range(from: 1, to: 8, with: [])
    let email = wisp.random_string(i) <> "@" <> wisp.random_string(i)
    let password = wisp.random_string(8)

    let assert Ok(user) = user.register(context.database, "", email, password)
    [user.id, ..acc]
  }

  let want = set.from_list(members)
  let assert Ok(got) =
    result.map(
      startup.assign_members(context.database, startup.id, members),
      set.from_list,
    )

  assert set.difference(want, got) == set.from_list([])
}

pub fn get_startup_members_test() -> Nil {
  use context <- server_test.with_context()

  let assert Ok(segment) = segment.register(context.database, "", "")

  let cnpj = wisp.random_string(14)
  let assert Ok(startup) =
    startup.register(context.database, segment.id, "", cnpj, "", "", "")

  let members = {
    use acc, i <- int.range(from: 1, to: 8, with: [])
    let email = wisp.random_string(i) <> "@" <> wisp.random_string(i)
    let password = wisp.random_string(8)

    let assert Ok(user) = user.register(context.database, "", email, password)
    [user, ..acc]
  }

  let assert Ok(_members_uuid) =
    startup.assign_members(
      context.database,
      startup.id,
      list.map(members, fn(member) { member.id }),
    )

  let want = set.from_list(members)
  let assert Ok(got) =
    result.map(startup.get_members(context.database, startup.id), set.from_list)

  assert set.difference(want, got) == set.from_list([])
}
