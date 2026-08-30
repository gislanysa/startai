import argus
import gleam/result
import gleam/string
import gleam/time/timestamp
import pog
import server/user/sql
import youid/uuid

pub type UserError {
  /// Failed to hash the user password
  HashError(argus.HashError)
  /// Failed to connect to the Database
  DatabaseError(pog.QueryError)
  /// Failed to register an User
  FailedToRegisterUser
  /// User was not found in the Database
  NotFound
  /// User emails need to be unique
  EmailConflict
  /// User email has invalid format
  InvalidEmailFormat
}

/// User's account.
pub type User {
  User(
    /// User ID
    id: uuid.Uuid,
    /// Name of the User
    full_name: String,
    /// Email of the User
    email: String,
    /// Argon2 encrypted password.
    /// Use `argus.verify` to compare passwords.
    password_hash: String,
    /// Timestamp of when the user was registred.
    created_at: timestamp.Timestamp,
    /// If the User is active or not.
    is_active: Bool,
  )
}

/// Register a new user in the Database.
///
/// ## Examples
///
/// ```gleam
/// let result = user.register(
///   context.database,
///   "Vinizin",
///   "vinizin@criticlevel.br",
///   "senha123",
/// )
///
/// case result {
///   Ok(data) -> todo as "send response"
///   Error(_) -> wisp.internal_server_error()
/// }
/// ```
pub fn register(
  database: pog.Connection,
  full_name full_name: String,
  email email: String,
  password password: String,
) -> Result(User, UserError) {
  use email <- result.try(case string.split_once(email, "@") {
    Ok(#("", _)) | Ok(#(_, "")) | Error(_) -> Error(InvalidEmailFormat)
    Ok(_) -> Ok(email)
  })

  use output <- result.try(
    argus.hasher()
    |> argus.hash(password)
    |> result.map_error(HashError),
  )

  use returned <- result.try(
    case sql.register(database, full_name, email, output.encoded_hash) {
      Error(pog.ConstraintViolated(constraint: "user_account_email_key", ..)) ->
        Error(EmailConflict)

      Ok(data) -> Ok(data)
      Error(err) -> Error(DatabaseError(err))
    },
  )

  case returned.rows {
    [] -> Error(FailedToRegisterUser)
    [row, ..] ->
      Ok(User(
        id: row.id,
        full_name: row.full_name,
        email: row.email,
        password_hash: row.password_hash,
        created_at: row.created_at,
        is_active: row.is_active,
      ))
  }
}

/// Search an user in the Database using their ID.
///
/// ## Examples
///
/// ```gleam
/// let result = user.get(context.database, id)
///
/// case result {
///   Ok(data) -> todo as "send response"
///   Error(user.NotFound) -> wisp.not_found()
///   Error(_) -> wisp.internal_server_error()
/// }
/// ```
pub fn get(database: pog.Connection, id: uuid.Uuid) -> Result(User, UserError) {
  use returned <- result.try(
    sql.get(database, id)
    |> result.map_error(DatabaseError),
  )

  case returned.rows {
    [] -> Error(NotFound)
    [row, ..] ->
      Ok(User(
        id: row.id,
        full_name: row.full_name,
        email: row.email,
        password_hash: row.password_hash,
        created_at: row.created_at,
        is_active: row.is_active,
      ))
  }
}
