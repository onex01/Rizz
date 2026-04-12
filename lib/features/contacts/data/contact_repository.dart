import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/contact.dart';

class ContactRepository {
  final FirebaseFirestore _firestore;

  ContactRepository(this._firestore);

  Future<void> addContact(String userId, String contactId, Contact contact) async {
    await _firestore.collection('users').doc(userId).update({
      'contacts.$contactId': contact.toMap(),
    });
  }

  Future<void> removeContact(String userId, String contactId) async {
    await _firestore.collection('users').doc(userId).update({
      'contacts.$contactId': FieldValue.delete(),
    });
  }

  Future<void> blockContact(String userId, String contactId, bool block) async {
    await _firestore.collection('users').doc(userId).update({
      'contacts.$contactId.isBlocked': block,
    });
  }

  Stream<Map<String, Contact>> getContacts(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data()?['contacts'] as Map<String, dynamic>? ?? {};
      return data.map((key, value) => MapEntry(key, Contact.fromMap(value)));
    });
  }
}