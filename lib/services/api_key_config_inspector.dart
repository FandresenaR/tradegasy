import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyConfigInspector {
  // Obtenir les informations sur la configuration des clés API
  static Future<Map<String, String>> getApiKeyConfigInfo() async {
    final Map<String, String> configInfo = {};

    // Vérifier les clés dans .env
    try {
      await dotenv.load(fileName: '.env');
      configInfo['BINANCE_API_KEY_ENV'] =
          dotenv.env['BINANCE_API_KEY'] != null
              ? 'Défini dans .env'
              : 'Non défini dans .env';
      configInfo['BINANCE_API_SECRET_ENV'] =
          dotenv.env['BINANCE_API_SECRET'] != null
              ? 'Défini dans .env'
              : 'Non défini dans .env';
      configInfo['OPENROUTER_API_KEY_ENV'] =
          dotenv.env['OPENROUTER_API_KEY'] != null
              ? 'Défini dans .env'
              : 'Non défini dans .env';
    } catch (e) {
      configInfo['ENV_ERROR'] = 'Erreur de chargement du fichier .env: $e';
    }

    // Vérifier les clés dans secure storage
    try {
      final storage = FlutterSecureStorage();
      final binanceApiKey = await storage.read(key: 'binance_api_key');
      final binanceSecretKey = await storage.read(key: 'binance_secret_key');
      final openrouterApiKey = await storage.read(key: 'openrouter_api_key');

      configInfo['BINANCE_API_KEY_STORAGE'] =
          binanceApiKey != null
              ? 'Défini dans secure storage'
              : 'Non défini dans secure storage';
      configInfo['BINANCE_API_SECRET_STORAGE'] =
          binanceSecretKey != null
              ? 'Défini dans secure storage'
              : 'Non défini dans secure storage';
      configInfo['OPENROUTER_API_KEY_STORAGE'] =
          openrouterApiKey != null
              ? 'Défini dans secure storage'
              : 'Non défini dans secure storage';
    } catch (e) {
      configInfo['STORAGE_ERROR'] = 'Erreur de lecture dans secure storage: $e';
    }

    // Identifier les emplacements des fichiers de configuration
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final projDir = Directory('${appDir.path}/..');

      configInfo['APP_DIR'] = appDir.path;

      // Chercher les fichiers .env
      final findEnvFiles = await _findFiles(projDir, '.env');
      configInfo['ENV_FILES'] = findEnvFiles.join('\n');
    } catch (e) {
      configInfo['FILE_SEARCH_ERROR'] =
          'Erreur lors de la recherche de fichiers: $e';
    }

    return configInfo;
  }

  // Afficher les informations sur la configuration des clés API
  static void showApiKeyConfigInfo(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Configuration des clés API'),
            content: FutureBuilder<Map<String, String>>(
              future: getApiKeyConfigInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                }

                final data = snapshot.data ?? {};

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Fichier .env:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(data['BINANCE_API_KEY_ENV'] ?? 'Non disponible'),
                      Text(data['BINANCE_API_SECRET_ENV'] ?? 'Non disponible'),
                      Text(data['OPENROUTER_API_KEY_ENV'] ?? 'Non disponible'),
                      SizedBox(height: 8),

                      Text(
                        'Secure Storage:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(data['BINANCE_API_KEY_STORAGE'] ?? 'Non disponible'),
                      Text(
                        data['BINANCE_API_SECRET_STORAGE'] ?? 'Non disponible',
                      ),
                      Text(
                        data['OPENROUTER_API_KEY_STORAGE'] ?? 'Non disponible',
                      ),
                      SizedBox(height: 8),

                      Text(
                        'Fichiers .env trouvés:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(data['ENV_FILES'] ?? 'Aucun fichier trouvé'),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  // Rechercher des fichiers avec un certain nom
  static Future<List<String>> _findFiles(
    Directory startDir,
    String pattern,
  ) async {
    List<String> result = [];

    try {
      final List<FileSystemEntity> entities = await startDir.list().toList();

      for (var entity in entities) {
        if (entity is File && entity.path.endsWith(pattern)) {
          result.add(entity.path);
        } else if (entity is Directory) {
          // Ne pas entrer dans certains répertoires (comme .git, build, etc.)
          final dirName = entity.path.split(Platform.pathSeparator).last;
          if (!dirName.startsWith('.') &&
              dirName != 'build' &&
              dirName != 'android' &&
              dirName != 'ios') {
            final subDirResults = await _findFiles(entity, pattern);
            result.addAll(subDirResults);
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la recherche dans ${startDir.path}: $e');
    }

    return result;
  }
}
