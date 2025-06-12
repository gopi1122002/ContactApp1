// import 'package:flutter/material.dart';
// import 'package:flutter_contacts/flutter_contacts.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class ContactDetails extends StatelessWidget {
// final Contact contact;
//
// const ContactDetails({super.key, required this.contact});
//
// @override
// Widget build(BuildContext context) {
//          return Scaffold(
//            appBar: AppBar(
//          title: Text(contact.displayName),
//          backgroundColor: Colors.blue,
// ),
//   body: ListView(
//        padding: const EdgeInsets.all(16),
//          children: [
//            if (contact.phones.isNotEmpty)
//        ...contact.phones
//     .map((phone) => ListTile(
// leading: const Icon(Icons.phone),
//       title: Text(phone.number),
//        subtitle: Text(phone.label.toString().split('.').last),
// ))
//     .toList(),
//            if (contact.emails.isNotEmpty)
//           ...contact.emails
//     .map((email) => ListTile(
// leading: const Icon(Icons.email),
//             title: Text(email.address),
//             subtitle: Text(email.label.toString().split('.').last),
//           )
//           )
//     .toList(),
//          ],
//   ),
//          );
// }
// }