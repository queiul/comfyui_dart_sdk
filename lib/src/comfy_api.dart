import 'dart:convert';

import 'package:dio/dio.dart';

/// SDK for interacting with the ComfyUI API.
class ComfyApi {
  final Dio _dio;
  final String url;

  /// Initializes the ComfyApi instance with the base URL.
  ComfyApi(String baseUrl, {Dio? dio})
      : url = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _dio = dio ?? Dio();

  /// Common GET request handler.
  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get('$url$path',
          queryParameters: queryParameters, options: options);
      return response.data;
    } on DioError catch (e) {
      print('GET request failed for $url$path: ${e.message}');
      rethrow;
    }
  }

  /// Common POST request handler.
  Future<Map<String, dynamic>> _post(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.post('$url$path', data: data);
      return response.data;
    } on DioError catch (e) {
      print('POST request failed for $url$path: ${e.message}');
      rethrow;
    }
  }

  /// Common DELETE request handler.
  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final response = await _dio.delete('$url$path');
      return response.data;
    } on DioError catch (e) {
      print('DELETE request failed for $url$path: ${e.message}');
      rethrow;
    }
  }

  /// Retrieves the current status of the prompt queue.
  Future<Map<String, dynamic>> getPrompt() => _get('prompt');

  /// Retrieves a list of extension URLs to import.
  Future<List<dynamic>> getExtensions() async {
    return (await _get('extensions'))['extensions'];
  }

  /// Retrieves a list of embedding names.
  Future<List<dynamic>> getEmbeddings() async {
    return (await _get('embeddings'))['embeddings'];
  }

  /// Retrieves node object definitions for the graph.
  Future<Map<String, dynamic>> getObjectInfo([String? nodeClass]) =>
      _get('object_info${nodeClass == null ? '' : '/$nodeClass'}');

  /// Retrieves the queue's current state.
  Future<Map<String, dynamic>> getQueue() => _get('queue');

  /// Retrieves the prompt execution history.
  Future<Map<String, dynamic>> getHistory() => _get('history');

  /// Retrieves history for a specific prompt by ID.
  Future<Map<String, dynamic>> getHistoryById(String promptId) =>
      _get('history/$promptId');

  /// Retrieves system and device stats.
  Future<Map<String, dynamic>> getSystemStatus() => _get('system_stats');

  /// Retrieves all setting values for the current user.
  Future<Map<String, dynamic>> getSettings() => _get('settings');

  /// Retrieves a specific setting value by ID.
  Future<Map<String, dynamic>> getSettingsById(String id) =>
      _get('settings/$id');

  /// Retrieves a user data file.
  Future<Map<String, dynamic>> getUserDataFile(String file) =>
      _get('userdata/$file');

  /// Retrieves a list of model files from a specific folder.
  Future<List<dynamic>> getModels(String folder) async {
    return (await _get('models/$folder'))['models'];
  }

  /// Retrieves metadata for a specific model file.
  Future<Map<String, dynamic>> getModelMetadata(
      String folderName, String filename) async {
    return await _get('view_metadata/$folderName?filename=$filename');
  }

  /// Retrieves an image for viewing.
  Future<Response> getImage(Map<String, dynamic>? queryParameters) async {
    return await _dio.get(
      '$url/view',
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );
  }

  /// Queues a new prompt.
  Future<Map<String, dynamic>> postPrompt(
    Map<String, dynamic> promptData, [
    String? clientId,
  ]) async {
    return await _post('prompt', data: jsonEncode({"prompt": promptData}));
  }

  /// Interrupts the running prompt.
  Future<Map<String, dynamic>> postInterrupt() => _post('interrupt');

  /// Manages the queue (clear or delete items).
  Future<Map<String, dynamic>> postQueueManagement(
          Map<String, dynamic> managementData) =>
      _post('queue', data: managementData);

  /// Frees up system resources.
  Future<Map<String, dynamic>> postFreeResources(
          Map<String, dynamic> freeOptions) =>
      _post('free', data: freeOptions);

  /// Manages history (clear or delete items).
  Future<Map<String, dynamic>> postHistoryManagement(
          Map<String, dynamic> managementData) =>
      _post('history', data: managementData);

  /// Uploads an image file.
  Future<Map<String, dynamic>> postUploadImage(FormData imageData) =>
      _post('upload/image', data: imageData);

  /// Uploads a mask image.
  Future<Map<String, dynamic>> postUploadMask(FormData maskData) =>
      _post('upload/mask', data: maskData);

  /// Initiates model download.
  Future<Map<String, dynamic>> postDownloadModel(
          Map<String, dynamic> downloadDetails) =>
      _post('internal/models/download', data: downloadDetails);

  /// Creates a new user.
  Future<Map<String, dynamic>> postUsers(Map<String, dynamic> userData) =>
      _post('users', data: userData);

  /// Stores settings for the current user.
  Future<Map<String, dynamic>> postSettings(
          Map<String, dynamic> settingsData) =>
      _post('settings', data: settingsData);

  /// Stores a specific setting by ID.
  Future<Map<String, dynamic>> postSettingsById(
          String id, dynamic settingValue) =>
      _post('settings/$id', data: settingValue);

  /// Stores a user data file.
  Future<Map<String, dynamic>> postUserDataFile(
          String file, dynamic fileContents) =>
      _post('userdata/$file', data: fileContents);

  /// Deletes an item from the queue by ID.
  Future<Map<String, dynamic>> deleteQueueItem(String id) =>
      _delete('queue/$id');

  /// Deletes an item from history by ID.
  Future<Map<String, dynamic>> deleteHistoryItem(String id) =>
      _delete('history/$id');
}
