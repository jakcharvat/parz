import gleam/regexp
import gleam/string
import parz/types.{type Parser, ParserState}

pub fn str(start) -> Parser(String) {
  fn(input) {
    case string.starts_with(input, start) {
      False -> Error("Expected " <> start <> " but found " <> input)
      True -> {
        let remaining = string.drop_start(input, string.length(start))
        Ok(ParserState(start, remaining))
      }
    }
  }
}

pub fn regex(regex) {
  fn(input) {
    case regexp.from_string(regex) {
      Error(_) -> Error("Invalid Regex Provided " <> regex)
      Ok(re) -> {
        case regexp.scan(re, input) {
          [] ->
            Error(
              "String does not match Regex: " <> regex <> "String: " <> input,
            )
          [match, ..] -> {
            let remaining =
              string.drop_start(input, string.length(match.content))
            Ok(ParserState(match.content, remaining))
          }
        }
      }
    }
  }
}

pub fn letters() {
  regex("^[A-Za-z]+")
}

pub fn digits() {
  regex("^[0-9]+")
}
