import gleam/bool
import gleam/list
import gleam/result
import gleam/string
import gleam/time/timestamp
import pog
import server/startup/sql
import server/user
import youid/uuid

pub type StartupError {
  /// Failed to connect to the Database
  DatabaseError(pog.QueryError)
  /// Something went wrong when registering a Startup
  FailedToRegisterStartup
  /// Startup was not found in the Database
  NotFound
  /// Invalid CNPJ format
  InvalidCnpjFormat
  /// Startup CNPJ must be unique
  CnpjConflict
}

pub type Startup {
  Startup(
    /// Startup ID
    id: uuid.Uuid,
    /// Startup's segment.
    segment_id: uuid.Uuid,
    /// Their name
    name: String,
    /// Their CPNJ, it must be exactly 14 digits
    cnpj: String,
    /// A description
    description: String,
    /// The city where it is located
    city: String,
    /// The state of where it is located
    state: String,
    /// When the startup was created
    created_at: timestamp.Timestamp,
  )
}

/// Register an empty startup in the Database
///
/// ## Examples
///
/// ```gleam
/// let result = startup.register(
///   context.database,
///   id,
///   "Critic Level",
///   "12345678901234",
///   "startup muito maneira",
///   "Recife",
///   "Pernambuco",
/// )
///
/// case result {
///   Ok(data) -> todo as "send response"
///   Error(_) -> wisp.internal_server_error()
/// }
/// ```
pub fn register(
  database: pog.Connection,
  segment_id segment: uuid.Uuid,
  name name: String,
  cnpj cnpj: String,
  description description: String,
  city city: String,
  state state: String,
) -> Result(Startup, StartupError) {
  use <- bool.guard(string.length(cnpj) != 14, Error(InvalidCnpjFormat))

  use returned <- result.try(
    case sql.register(database, segment, name, cnpj, description, city, state) {
      Error(pog.ConstraintViolated(constraint: "startup_cnpj_key", ..)) ->
        Error(CnpjConflict)

      Ok(data) -> Ok(data)
      Error(err) -> Error(DatabaseError(err))
    },
  )

  case returned.rows {
    [] -> Error(FailedToRegisterStartup)
    [row, ..] ->
      Ok(Startup(
        id: row.id,
        segment_id: row.segment_id,
        name: row.name,
        cnpj: row.cnpj,
        description: row.description,
        city: row.city,
        state: row.state,
        created_at: row.created_at,
      ))
  }
}

/// Search a startup in the Database using their ID.
///
/// ## Examples
///
/// ```gleam
/// let result = startup.get(context.database, id)
///
/// case result {
///   Ok(data) -> todo as "send response"
///   Error(startup.NotFound) -> wisp.not_found()
///   Error(_) -> wisp.internal_server_error()
/// }
/// ```
pub fn get(
  database: pog.Connection,
  id: uuid.Uuid,
) -> Result(Startup, StartupError) {
  use returned <- result.try(
    sql.get(database, id)
    |> result.map_error(DatabaseError),
  )

  case returned.rows {
    [] -> Error(NotFound)
    [row, ..] ->
      Ok(Startup(
        id: row.id,
        segment_id: row.segment_id,
        name: row.name,
        cnpj: row.cnpj,
        description: row.description,
        city: row.city,
        state: row.state,
        created_at: row.created_at,
      ))
  }
}

/// Assign a list of members to a Startup and returns
/// the ID of all successfully assigned Users.
///
/// ## Examples
///
/// ```gleam
/// let result = startup.assign_members(context.database, id, [member])
///
/// case result {
///   Ok(assigned) -> todo as "send response"
///   Error(_) -> wisp.internal_server_error()
/// }
/// ```
pub fn assign_members(
  database: pog.Connection,
  id: uuid.Uuid,
  assign members: List(uuid.Uuid),
) -> Result(List(uuid.Uuid), StartupError) {
  use returned <- result.map(
    sql.assign_members(database, id, members)
    |> result.map_error(DatabaseError),
  )

  list.map(returned.rows, fn(row) { row.user_id })
}

/// Get all members assigned to a given Startup.
///
/// ## Examples
///
/// ```gleam
/// let result = startup.get_members(context.database, id)
///
/// case result {
///   Ok(members) -> todo as "send response"
///   Error(_) -> wisp.internal_server_error()
/// }
/// ```
pub fn get_members(
  database: pog.Connection,
  id: uuid.Uuid,
) -> Result(List(user.User), StartupError) {
  use returned <- result.map(
    sql.get_members(database, id)
    |> result.map_error(DatabaseError),
  )

  list.map(returned.rows, fn(row) {
    user.User(
      id: row.id,
      full_name: row.full_name,
      email: row.email,
      password_hash: row.password_hash,
      created_at: row.created_at,
      is_active: row.is_active,
    )
  })
}
