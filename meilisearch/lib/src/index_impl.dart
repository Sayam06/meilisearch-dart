import 'package:dio/dio.dart';

import 'client.dart';
import 'client_impl.dart';
import 'index.dart';
import 'pending_update_impl.dart';
import 'search_result.dart';

class MeiliSearchIndexImpl implements MeiliSearchIndex {
  MeiliSearchIndexImpl(
    this.client,
    this.uid, {
    this.primaryKey,
    this.createdAt,
    this.updatedAt,
  });

  final MeiliSearchClientImpl client;

  @override
  final String uid;

  @override
  String primaryKey;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Dio get dio => client.dio;

  factory MeiliSearchIndexImpl.fromMap(
    MeiliSearchClient client,
    Map<String, dynamic> map,
  ) =>
      MeiliSearchIndexImpl(
        client,
        map['uid'] as String,
        primaryKey: map['primaryKey'] as String,
        createdAt: DateTime.tryParse(map['createdAt'] as String),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String),
      );

  //
  // Index endpoints
  //

  @override
  Future<void> update({String primaryKey}) async {
    final data = <String, dynamic>{
      'primaryKey': primaryKey,
    };
    data.removeWhere((k, v) => v == null);
    final response = await dio.put('/indexes/$uid', data: data);

    primaryKey = response.data['primaryKey'] as String;
    createdAt = DateTime.parse(response.data['createdAt'] as String);
    updatedAt = DateTime.parse(response.data['updatedAt'] as String);
  }

  @override
  Future<void> delete() async {
    await dio.delete('/indexes/$uid');
  }

  //
  // Search endpoints
  //

  @override
  Future<SearchResult> search<T>(
    String query, {
    int offset,
    int limit,
    String filters,
    facetFilters,
    List<String> facetsDistribution,
    List<String> attributesToRetrieve,
    List<String> attributesToCrop,
    List<String> cropLength,
    List<String> attributesToHighlight,
    bool matches,
  }) async {
    final data = <String, dynamic>{
      'q': query,
      'offset': offset,
      'limit': limit,
      'filters': filters,
      'facetFilters': facetFilters,
      'facetsDistribution': facetsDistribution,
      'attributesToRetrieve': attributesToRetrieve,
      'attributesToCrop': attributesToCrop,
      'cropLength': cropLength,
      'attributesToHighlight': attributesToHighlight,
      'matches': matches,
    };
    data.removeWhere((k, v) => v == null);
    final response = await dio.post('/indexes/$uid/search', data: data);

    return SearchResult.fromMap(response.data);
  }

  //
  // Document endpoints
  //

  Future<PendingUpdateImpl> _update(Future<Response> future) async {
    final response = await future;
    return PendingUpdateImpl.fromMap(this, response.data);
  }

  @override
  Future<PendingUpdateImpl> addDocuments(documents, {String primaryKey}) async {
    return await _update(dio.post(
      '/indexes/$uid/documents',
      data: documents,
      queryParameters: <String, dynamic>{
        if (primaryKey != null) 'primaryKey': primaryKey,
      },
    ));
  }

  @override
  Future<PendingUpdateImpl> updateDocuments(
    documents, {
    String primaryKey,
  }) async {
    return await _update(dio.put(
      '/indexes/$uid/documents',
      data: documents,
      queryParameters: <String, dynamic>{
        if (primaryKey != null) 'primaryKey': primaryKey,
      },
    ));
  }

  @override
  Future<PendingUpdateImpl> deleteAllDocuments() async {
    return await _update(dio.delete('/indexes/$uid/documents'));
  }

  @override
  Future<PendingUpdateImpl> deleteDocument(dynamic id) async {
    return await _update(dio.delete('/indexes/$uid/documents/$id'));
  }

  @override
  Future<PendingUpdateImpl> deleteDocuments(List ids) async {
    return await _update(dio.post(
      '/indexes/$uid/documents/delete-batch',
      data: ids,
    ));
  }

  @override
  Future<Map<String, dynamic>> getDocument(id) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/indexes/$uid/documents/$id',
    );

    return response.data;
  }

  @override
  Future<List<Map<String, dynamic>>> getDocuments({
    int offset,
    int limit,
    String attributesToRetrieve = '*',
  }) async {
    final response = await dio.get<List<dynamic>>(
      '/indexes/$uid/documents',
      queryParameters: <String, dynamic>{
        if (offset != null) 'offset': offset,
        if (limit != null) 'limit': limit,
        if (attributesToRetrieve != null)
          'attributesToRetrieve': attributesToRetrieve,
      },
    );

    return response.data.cast<Map<String, dynamic>>();
  }
}
