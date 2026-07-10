import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:visionmax/pages/home_page.dart';
import 'package:visionmax/themes/dark_mode.dart';
import 'package:visionmax/themes/light_mode.dart';
import 'package:visionmax/themes/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Vision Max',
            theme: lightMode,
            darkTheme: darkMode,
            themeMode: themeMode,
            home: const HomePage(),
            builder: (context, child) => ScaffoldMessenger(child: child!),
          );
        },
      ),
    );
  }
}


