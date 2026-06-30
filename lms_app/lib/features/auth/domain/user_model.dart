class UserModel {
  final String idUser;
  final String nomUser;
  final String prenomUser;
  final String emailUser;
  final String roleUser;

  UserModel({
    required this.idUser,
    required this.nomUser,
    required this.prenomUser,
    required this.emailUser,
    required this.roleUser,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['idUser'],
      nomUser: json['nomUser'],
      prenomUser: json['prenomUser'],
      emailUser: json['emailUser'],
      roleUser: json['roleUser'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idUser': idUser,
      'nomUser': nomUser,
      'prenomUser': prenomUser,
      'emailUser': emailUser,
      'roleUser': roleUser,
    };
  }
}