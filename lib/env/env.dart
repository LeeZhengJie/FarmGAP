import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'MAPBOX_ACCESS_TOKEN', obfuscate: true)
  static final mapboxAccessToken = _Env.mapboxAccessToken;
}