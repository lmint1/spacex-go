import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'cubits/index.dart';
import 'repositories-cubit/index.dart';
import 'services/index.dart';
import 'util/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedCubit.storage = await HydratedStorage.build();

  Bloc.observer = CherryBlocObserver();

  final httpClient = Dio();

  final motificationsCubit = NotificationsCubit(
    FlutterLocalNotificationsPlugin(),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'channel.launches',
        'Launches notifications',
        'Stay up-to-date with upcoming SpaceX launches',
        importance: Importance.high,
      ),
      iOS: IOSNotificationDetails(),
    ),
    initializationSettings: InitializationSettings(
      android: AndroidInitializationSettings('notification_launch'),
      iOS: IOSInitializationSettings(),
    ),
  );
  await motificationsCubit.init();

  runApp(CherryApp(
    themeCubit: ThemeCubit(),
    imageQualityCubit: ImageQualityCubit(),
    notificationsCubit: motificationsCubit,
    vehiclesRepository: VehiclesRepository(
      VehiclesService(httpClient),
    ),
    launchesRepository: LaunchesRepository(
      LaunchesService(httpClient),
    ),
    achievementsRepository: AchievementsRepository(
      AchievementsService(httpClient),
    ),
    companyRepository: CompanyRepository(
      CompanyService(httpClient),
    ),
  ));
}

/// Builds the neccesary cubits, as well as the home page.
class CherryApp extends StatelessWidget {
  final ThemeCubit themeCubit;
  final ImageQualityCubit imageQualityCubit;
  final NotificationsCubit notificationsCubit;
  final VehiclesRepository vehiclesRepository;
  final LaunchesRepository launchesRepository;
  final AchievementsRepository achievementsRepository;
  final CompanyRepository companyRepository;

  const CherryApp({
    this.themeCubit,
    this.imageQualityCubit,
    this.notificationsCubit,
    this.vehiclesRepository,
    this.launchesRepository,
    this.achievementsRepository,
    this.companyRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => themeCubit),
        BlocProvider(create: (_) => imageQualityCubit),
        BlocProvider(create: (_) => notificationsCubit),
        BlocProvider(create: (_) => VehiclesCubit(vehiclesRepository)),
        BlocProvider(create: (_) => LaunchesCubit(launchesRepository)),
        BlocProvider(create: (_) => AchievementsCubit(achievementsRepository)),
        BlocProvider(create: (_) => CompanyCubit(companyRepository))
      ],
      child: BlocConsumer<ThemeCubit, ThemeState>(
        listener: (context, state) => null,
        builder: (context, state) => MaterialApp(
          title: 'SpaceX GO!',
          theme: context.watch<ThemeCubit>().lightTheme,
          darkTheme: context.watch<ThemeCubit>().darkTheme,
          themeMode: context.watch<ThemeCubit>().themeMode,
          onGenerateRoute: Routes.generateRoute,
          onUnknownRoute: Routes.errorRoute,
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(),
            )..load(null),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate
          ],
        ),
      ),
    );
  }
}

class CherryBlocObserver extends BlocObserver {
  @override
  void onCreate(Cubit cubit) {
    super.onCreate(cubit);
    print('onCreate: ${cubit.runtimeType}');
  }

  @override
  void onChange(Cubit cubit, Change change) {
    super.onChange(cubit, change);
    print('onChange: ${cubit.runtimeType}, $change');
  }

  @override
  void onError(Cubit cubit, Object error, StackTrace stackTrace) {
    super.onError(cubit, error, stackTrace);
    print('onError: ${cubit.runtimeType}, $error');
  }
}
