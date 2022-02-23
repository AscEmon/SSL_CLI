class GraphQLErrorResponse {
  GraphQLErrorResponse({
    required this.errors,
  });

  late final List<Errors> errors;

  GraphQLErrorResponse.fromJson(Map<String, dynamic> json) {
    errors = List.from(json['errors']).map((e) => Errors.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['errors'] = errors.map((e) => e.toJson()).toList();
    return _data;
  }
}

class Errors {
  Errors({
    required this.message,
  });

  late final String message;

  Errors.fromJson(Map<String, dynamic> json) {
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['message'] = message;
    return _data;
  }
}
