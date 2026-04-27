// T03: Result型 — 例外を値として扱う

sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T get value => (this as Ok<T>).value;
  Object get error => (this as Err<T>).error;

  R fold<R>({
    required R Function(T value) ok,
    required R Function(Object error) err,
  }) {
    return switch (this) {
      Ok(:final value) => ok(value),
      Err(:final error) => err(error),
    };
  }

  Result<R> map<R>(R Function(T value) fn) {
    return switch (this) {
      Ok(:final value) => Ok(fn(value)),
      Err(:final error) => Err(error),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  @override
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  @override
  final Object error;
}

extension ResultFuture<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      return Ok(await this);
    } catch (e) {
      return Err(e);
    }
  }
}
