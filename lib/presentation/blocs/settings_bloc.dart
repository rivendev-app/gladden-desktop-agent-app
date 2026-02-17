import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/storage/secure_storage_service.dart';
import '../../core/providers/base_ai_provider.dart';
import '../../infrastructure/providers/openai/openai_provider.dart';
import '../../infrastructure/providers/gemini/gemini_provider.dart';
import '../../infrastructure/storage/objectbox_store.dart';
import '../../infrastructure/storage/objectbox_entities.dart';

abstract class SettingsEvent {}
class LoadSettings extends SettingsEvent {}
class SaveApiKey extends SettingsEvent {
  final String providerId;
  final String apiKey;
  SaveApiKey(this.providerId, this.apiKey);
}
class DeleteApiKey extends SettingsEvent {
  final String providerId;
  DeleteApiKey(this.providerId);
}
class UpdateBudget extends SettingsEvent {
  final double limit;
  final bool block;
  UpdateBudget({required this.limit, required this.block});
}

class SettingsState {
  final Map<String, String> apiKeys;
  final Map<String, List<String>> availableModels;
  final double budgetLimit;
  final bool blockOnLimit;
  final bool isLoading;
  final String? error;

  SettingsState({
    this.apiKeys = const {},
    this.availableModels = const {},
    this.budgetLimit = 0.0,
    this.blockOnLimit = false,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    Map<String, String>? apiKeys,
    Map<String, List<String>>? availableModels,
    double? budgetLimit,
    bool? blockOnLimit,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      apiKeys: apiKeys ?? this.apiKeys,
      availableModels: availableModels ?? this.availableModels,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      blockOnLimit: blockOnLimit ?? this.blockOnLimit,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SecureStorageService _storage;
  final ObjectBoxStore _store;
  final List<BaseAIProvider> _providers = [
    OpenAIProvider(),
    GeminiProvider(),
  ];

  SettingsBloc(this._storage, this._store) : super(SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveApiKey>(_onSaveApiKey);
    on<DeleteApiKey>(_onDeleteApiKey);
    on<UpdateBudget>(_onUpdateBudget);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final keys = await _storage.getAllKeys();
      final Map<String, List<String>> models = {};
      
      for (final provider in _providers) {
        if (keys.containsKey(provider.id)) {
          models[provider.id] = await provider.getAvailableModels(keys[provider.id]!);
        }
      }

      final settingsBox = _store.store.box<AppSettingsEntity>();
      // Try to find existing settings or create new
      var settings = settingsBox.getAll().firstOrNull;
      if (settings == null) {
        settings = AppSettingsEntity();
        // Let ObjectBox assign the ID (starts at 1)
        settingsBox.put(settings);
      }
      
      emit(state.copyWith(
        apiKeys: keys, 
        availableModels: models, 
        budgetLimit: settings.budgetLimit,
        blockOnLimit: settings.blockOnLimit,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onUpdateBudget(UpdateBudget event, Emitter<SettingsState> emit) async {
    final settingsBox = _store.store.box<AppSettingsEntity>();
    var settings = settingsBox.getAll().firstOrNull;
    
    if (settings != null) {
      settings.budgetLimit = event.limit;
      settings.blockOnLimit = event.block;
    } else {
      settings = AppSettingsEntity(
        budgetLimit: event.limit, 
        blockOnLimit: event.block
      );
    }
    settingsBox.put(settings);
    emit(state.copyWith(budgetLimit: event.limit, blockOnLimit: event.block));
  }

  Future<void> _onSaveApiKey(SaveApiKey event, Emitter<SettingsState> emit) async {
    await _storage.saveApiKey(event.providerId, event.apiKey);
    add(LoadSettings());
  }

  Future<void> _onDeleteApiKey(DeleteApiKey event, Emitter<SettingsState> emit) async {
    await _storage.deleteApiKey(event.providerId);
    add(LoadSettings());
  }
}
