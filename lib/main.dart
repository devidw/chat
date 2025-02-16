import 'package:app/db.dart';
import 'package:app/global_store.dart';
import 'package:app/pages/home.dart';
import 'package:app/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final ThemeData lightTheme = ThemeData.light(
  useMaterial3: true,
).copyWith(
  scaffoldBackgroundColor: MyColors.white,
  dialogBackgroundColor: MyColors.white,
  textTheme: ThemeData.light().textTheme.apply(
        fontFamily: "NotoSerif",
        bodyColor: MyColors.light_txt,
      ),
  textSelectionTheme: TextSelectionThemeData(
    selectionColor: MyColors.a.withValues(alpha: 0.5),
    cursorColor: MyColors.a,
  ),
);

final ThemeData darkTheme = ThemeData.dark(
  useMaterial3: true,
).copyWith(
  scaffoldBackgroundColor: MyColors.black,
  dialogBackgroundColor: MyColors.black,
  textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: "NotoSerif",
        bodyColor: MyColors.dark_txt,
      ),
  textSelectionTheme: TextSelectionThemeData(
    selectionColor: MyColors.a.withValues(alpha: 0.5),
    cursorColor: MyColors.a,
  ),
);

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
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
