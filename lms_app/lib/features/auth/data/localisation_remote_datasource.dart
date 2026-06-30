import 'package:dio/dio.dart';

class LocalisationRemoteDatasource {
  final Dio _dio;

  LocalisationRemoteDatasource(this._dio);

  Future<List<dynamic>> getPays() async {
    final response = await _dio.get('/pays');
    return response.data;
  }

  Future<List<dynamic>> getVillesByPays(String idPays) async {
    final response = await _dio.get('/pays/$idPays/villes');
    return response.data;
  }

  Future<List<dynamic>> getOperateursByPays(String idPays) async {
    final response = await _dio.get('/pays/$idPays/operateurs');
    return response.data;
  }
}