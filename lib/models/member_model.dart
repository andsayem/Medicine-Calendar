class Member {
  final int? id;
  final String name;
  final String relation;

  Member({
    this.id,
    required this.name,
    this.relation = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'relation': relation,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      name: map['name'] as String,
      relation: map['relation'] as String? ?? '',
    );
  }
}
