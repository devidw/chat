import 'package:app/global_store.dart';
import 'package:app/pages/boot.dart';
import 'package:app/pages/home.dart';
import 'package:app/pages/settings.dart';
import 'package:app/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

final ThemeData lightTheme = ThemeData.light(useMaterial3: true).copyWith(
  scaffoldBackgroundColor: MyColors.white,
  textTheme: ThemeData.light().textTheme.apply(
        fontFamily: "NotoSerif",
        bodyColor: MyColors.light_txt,
      ),
  textSelectionTheme: TextSelectionThemeData(
    selectionColor: MyColors.a.withValues(alpha: 0.5),
    cursorColor: MyColors.a,
  ),
  dialogTheme: DialogThemeData(backgroundColor: MyColors.white),
);

final ThemeData darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
  scaffoldBackgroundColor: MyColors.black,
  textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: "NotoSerif",
        bodyColor: MyColors.dark_txt,
      ),
  textSelectionTheme: TextSelectionThemeData(
    selectionColor: MyColors.a.withValues(alpha: 0.5),
    cursorColor: MyColors.a,
  ),
  dialogTheme: DialogThemeData(backgroundColor: MyColors.black),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    // center: true,
    // size: Size(800, 600),
    // titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );

  windowManager.waitUntilReadyToShow(
    windowOptions,
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => GlobalStore())],
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
      initialRoute: '/boot',
      routes: {
        "/boot": (context) => BootPage(),
        "/": (context) => HomePage(),
        "/settings": (context) => SettingsPage(),
      },
    );
  }
}
