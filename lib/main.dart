import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final helloWorldProvider = Provider((_) => 'Hello World');
final userProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String helloWorld = ref.watch(helloWorldProvider);
    final AsyncValue<User?> user = ref.watch(userProvider);

    TextEditingController nameController = TextEditingController();

    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(title: Text(helloWorld)),
      body: Center(
        child: user.when(
          data: (user) {
            if (user == null) {
              // Sign in
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      onChanged: (value) {
                        nameController.text = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        return;
                      }
                      var credential =
                          await FirebaseAuth.instance.signInAnonymously();
                      var ref = FirebaseFirestore.instance
                          .collection('accounts')
                          .doc(credential.user!.uid);
                      await ref.set({'name': nameController.text});
                    },
                    child: const Text('Sign in'),
                  ),
                ],
              );
            } else {
              // Sign out
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'AUTH ID: ',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      children: [
                        TextSpan(
                            text: user.uid,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AccountDetails(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              );
            }
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text(error.toString()),
        ),
      ),
    ));
  }
}

// Listening to a stream of user data
final streamData = StreamProvider<Map?>((ref) {
  final userStream = ref.watch(userProvider);
  var user = userStream.asData?.value;

  if (user == null) {
    return Stream.value(null);
  } else {
    return FirebaseFirestore.instance
        .collection('accounts')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
});

// Displaying the user data
class AccountDetails extends ConsumerWidget {
  const AccountDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Map?> data = ref.watch(streamData);

    return data.when(
      data: (data) {
        if (data == null) {
          return const Text('No data');
        } else {
          return Text(data['name'],
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
                fontSize: 22.5,
              ));
        }
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text(error.toString()),
    );
  }
}
