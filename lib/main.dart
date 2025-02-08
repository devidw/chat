import 'package:app/db.dart';
import 'package:app/global_store.dart';
import 'package:app/pages/home.dart';
import 'package:app/styles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DATA.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GlobalStore()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat',
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        scaffoldBackgroundColor: MyColors.bg,
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: GoogleFonts.notoSerif().fontFamily,
              bodyColor: MyColors.txt,
            ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: MyColors.a.withValues(alpha: 0.5),
          cursorColor: MyColors.a,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
