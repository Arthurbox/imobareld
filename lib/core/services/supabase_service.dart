import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // --- Authentification ---
  
  Future<AuthResponse> signUp({required String email, required String password, Map<String, dynamic>? data, String? emailRedirectTo}) async {
    return await client.auth.signUp(email: email, password: password, data: data, emailRedirectTo: emailRedirectTo);
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  // --- Base de données (CRUD) ---

  Future<List<Map<String, dynamic>>> getTable(String table, {String select = '*', Map<String, dynamic>? filters}) async {
    var query = client.from(table).select(select);
    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }
    return await query;
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    await client.from(table).insert(data);
  }

  Future<void> update(String table, String id, Map<String, dynamic> data) async {
    await client.from(table).update(data).eq('id', id);
  }

  Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }

  // --- Storage ---

  Future<String> uploadFile(String bucket, String path, dynamic file) async {
    await client.storage.from(bucket).upload(path, file);
    return client.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> uploadBytes(String bucket, String path, dynamic bytes) async {
    await client.storage.from(bucket).uploadBinary(path, bytes);
    return client.storage.from(bucket).getPublicUrl(path);
  }
}

final supabaseService = SupabaseService();
