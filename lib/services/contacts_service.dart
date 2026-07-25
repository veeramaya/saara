import 'package:flutter_contacts/flutter_contacts.dart';

/// A minimal contact reference — only what participant matching needs. The full
/// contact (photo, numbers, etc.) is never read or stored (§1.4, §11).
class SimpleContact {
  const SimpleContact({required this.id, required this.name});
  final String id; // on-device contact id → stored as contact_lookup_key
  final String name;
}

/// §11 on-device contacts. Read-only, matched locally; nothing is uploaded.
class ContactsService {
  const ContactsService();

  /// Requests read permission just-in-time (§15). Returns false if denied.
  Future<bool> ensurePermission() =>
      FlutterContacts.requestPermission(readonly: true);

  /// All contacts with a display name, sorted. Properties/photos are not
  /// loaded (fast, and we only need the name).
  Future<List<SimpleContact>> all() async {
    final contacts = await FlutterContacts.getContacts();
    final out = <SimpleContact>[
      for (final c in contacts)
        if (c.displayName.trim().isNotEmpty)
          SimpleContact(id: c.id, name: c.displayName.trim()),
    ];
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  /// The phone number(s) for one contact, read **on demand** so we can place a
  /// call — never stored (§1.4, §11): Saara keeps only the name and the id, and
  /// looks the number up from the device address book at the moment you dial.
  /// Empty if the contact is gone, has no number, or permission is refused.
  Future<List<String>> phonesFor(String contactId) async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return const [];
    }
    final c = await FlutterContacts.getContact(contactId, withProperties: true);
    if (c == null) return const [];
    return [
      for (final p in c.phones)
        if (p.number.trim().isNotEmpty) p.number.trim(),
    ];
  }
}
