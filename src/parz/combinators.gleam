import gleam/list
import gleam/string
import parz/types.{type Parser, type ParserState, ParserState}

fn sequence_rec(
  parsers: List(Parser(a)),
  input: String,
  acc: ParserState(List(a)),
) -> Result(ParserState(List(a)), String) {
  case parsers {
    [] -> Ok(ParserState([], input))
    [first, ..rest] ->
      case first(input) {
        Error(err) -> Error(err)
        Ok(ok) ->
          case sequence_rec(rest, ok.remaining, acc) {
            Error(err) -> Error(err)
            Ok(rec) ->
              Ok(ParserState([ok.matched, ..rec.matched], rec.remaining))
          }
      }
  }
}

pub fn sequence(parsers: List(Parser(a))) {
  fn(input) { sequence_rec(parsers, input, ParserState([], input)) }
}

pub fn choice(parsers: List(Parser(a))) {
  fn(input) {
    case parsers {
      [] -> Error("No more choices provided")
      [first, ..rest] ->
        case first(input) {
          Ok(ok) -> Ok(ok)
          Error(err) ->
            case rest {
              [] -> Error(err)
              _ -> choice(rest)(input)
            }
        }
    }
  }
}

pub fn right(l: Parser(a), r: Parser(b)) -> Parser(b) {
  fn(input) {
    case l(input) {
      Error(err) -> Error(err)
      Ok(okl) ->
        case r(okl.remaining) {
          Error(err) -> Error(err)
          Ok(okr) -> Ok(ParserState(okr.matched, okr.remaining))
        }
    }
  }
}

pub fn left(l: Parser(a), r: Parser(b)) -> Parser(a) {
  fn(input) {
    case l(input) {
      Error(err) -> Error(err)
      Ok(okl) ->
        case r(okl.remaining) {
          Error(err) -> Error(err)
          Ok(okr) -> Ok(ParserState(okl.matched, okr.remaining))
        }
    }
  }
}

pub fn between(l: Parser(a), keep: Parser(b), r: Parser(c)) -> Parser(b) {
  fn(input) {
    case l(input) {
      Error(err) -> Error(err)
      Ok(okl) ->
        case left(keep, r)(okl.remaining) {
          Error(err) -> Error(err)
          Ok(okr) -> Ok(ParserState(okr.matched, okr.remaining))
        }
    }
  }
}

fn many_rec(
  parser: Parser(a),
  input,
  acc,
) -> Result(ParserState(List(a)), String) {
  case parser(input) {
    Error(err) -> Error(err)
    Ok(ok) -> {
      case many_rec(parser, ok.remaining, acc) {
        Error(_) -> Ok(ParserState([ok.matched], ok.remaining))
        Ok(rec) -> {
          Ok(ParserState([ok.matched, ..rec.matched], rec.remaining))
        }
      }
    }
  }
}

pub fn many1(parser: Parser(a)) {
  fn(input) { many_rec(parser, input, []) }
}

pub fn many(parser: Parser(a)) {
  fn(input) {
    case many1(parser)(input) {
      Error(_) -> Ok(ParserState([], input))
      Ok(ok) -> Ok(ok)
    }
  }
}

pub fn concat_str(parser) {
  map(parser, string.concat)
}

pub fn label_error(parser, message) {
  fn(input) {
    case parser(input) {
      Ok(ok) -> Ok(ok)
      Error(_) -> Error(message)
    }
  }
}

pub fn map(parser: Parser(a), transform) {
  fn(input) {
    case parser(input) {
      Error(err) -> Error(err)
      Ok(ok) -> Ok(ParserState(transform(ok.matched), ok.remaining))
    }
  }
}

pub fn map_token(parser: Parser(a), t) {
  map(parser, fn(_) { t })
}

pub fn try_map(parser: Parser(a), transform) {
  fn(input) {
    case parser(input) {
      Error(err) -> Error(err)
      Ok(ok) ->
        case transform(ok.matched) {
          Error(err) -> Error(err)
          Ok(t) -> Ok(ParserState(t, ok.remaining))
        }
    }
  }
}

pub fn as_list(parser: Parser(a)) {
  fn(input) {
    case parser(input) {
      Error(err) -> Error(err)
      Ok(ok) -> Ok(ParserState([ok.matched], ok.remaining))
    }
  }
}

pub fn separator1(parser: Parser(a), sep: Parser(_)) {
  choice([
    sequence([as_list(parser), many(right(sep, parser))]) |> map(list.flatten),
    as_list(parser),
  ])
}

pub fn separator(parser: Parser(a), sep: Parser(_)) {
  fn(input) {
    case separator1(parser, sep)(input) {
      Error(_) -> Ok(ParserState([], input))
      Ok(ok) -> Ok(ok)
    }
  }
}
