import 'package:get_it/get_it.dart';
import '../utils/app_logger.dart';

/// Service locator for dependency injection
final GetIt serviceLocator = GetIt.instance;

/// Dependency injection setup
class DependencyInjection {
  static bool _isInitialized = false;
  
  /// Initialize all dependencies
  static Future<void> init() async {
    if (_isInitialized) {
      AppLogger.warning('Dependency injection already initialized');
      return;
    }
    
    AppLogger.info('Initializing dependency injection');
    
    try {
      // Register core services
      await _registerCoreServices();
      
      // Register repositories
      await _registerRepositories();
      
      // Register providers
      await _registerProviders();
      
      // Register services
      await _registerServices();
      
      _isInitialized = true;
      AppLogger.info('Dependency injection initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize dependency injection', error: e);
      rethrow;
    }
  }
  
  /// Register core services
  static Future<void> _registerCoreServices() async {
    // Add core services here
    AppLogger.debug('Registering core services');
  }
  
  /// Register repositories
  static Future<void> _registerRepositories() async {
    // Add repositories here
    AppLogger.debug('Registering repositories');
  }
  
  /// Register providers
  static Future<void> _registerProviders() async {
    // Add providers here
    AppLogger.debug('Registering providers');
  }
  
  /// Register services
  static Future<void> _registerServices() async {
    // Add services here
    AppLogger.debug('Registering services');
  }
  
  /// Reset all dependencies (for testing)
  static Future<void> reset() async {
    if (!_isInitialized) {
      return;
    }
    
    AppLogger.info('Resetting dependency injection');
    await serviceLocator.reset();
    _isInitialized = false;
  }
  
  /// Check if dependencies are initialized
  static bool get isInitialized => _isInitialized;
}

/// Extension for easy service access
extension ServiceLocatorExtension on GetIt {
  /// Get service or throw
  T getOrThrow<T extends Object>() {
    if (!isRegistered<T>()) {
      throw Exception('Service ${T.toString()} is not registered');
    }
    return get<T>();
  }
  
  /// Get service or return null
  T? getOrNull<T extends Object>() => isRegistered<T>() ? get<T>() : null;
}

/// Lazy singleton registration helper
class LazySingleton<T extends Object> {
  final T Function() factory;
  final String? instanceName;
  
  const LazySingleton(this.factory, {this.instanceName});
  
  void register() {
    if (instanceName != null) {
      serviceLocator.registerLazySingleton<T>(factory, instanceName: instanceName);
    } else {
      serviceLocator.registerLazySingleton<T>(factory);
    }
  }
}

/// Factory registration helper
class Factory<T extends Object> {
  final T Function() factory;
  final String? instanceName;
  
  const Factory(this.factory, {this.instanceName});
  
  void register() {
    if (instanceName != null) {
      serviceLocator.registerFactory<T>(factory, instanceName: instanceName);
    } else {
      serviceLocator.registerFactory<T>(factory);
    }
  }
}

/// Singleton registration helper
class Singleton<T extends Object> {
  final T Function() factory;
  final String? instanceName;
  final DisposingFunc<T>? dispose;

  const Singleton(this.factory, {this.instanceName, this.dispose});

  void register() {
    if (instanceName != null) {
      serviceLocator.registerSingleton<T>(
        factory(),
        instanceName: instanceName,
        dispose: dispose,
      );
    } else {
      serviceLocator.registerSingleton<T>(
        factory(),
        dispose: dispose,
      );
    }
  }
}
