import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/storage/objectbox_entities.dart';
import '../../infrastructure/storage/objectbox_store.dart';
import 'package:intl/intl.dart';

abstract class UsageEvent {}

class LoadUsage extends UsageEvent {
  final DateTime? start;
  final DateTime? end;
  final String? model;
  final String? provider;

  LoadUsage({this.start, this.end, this.model, this.provider});
}

class UsageState {
  final List<ChatMessageEntity> items;
  final Map<String, double> costByProvider;
  final Map<String, double> costByModel;
  final Map<String, double> dailyCost;
  final DateTime? start;
  final DateTime? end;
  final String? model;
  final String? provider;
  final bool isLoading;
  final String? error;

  UsageState({
    this.items = const [],
    this.costByProvider = const {},
    this.costByModel = const {},
    this.dailyCost = const {},
    this.start,
    this.end,
    this.model,
    this.provider,
    this.isLoading = false,
    this.error,
  });

  UsageState copyWith({
    List<ChatMessageEntity>? items,
    Map<String, double>? costByProvider,
    Map<String, double>? costByModel,
    Map<String, double>? dailyCost,
    DateTime? start,
    DateTime? end,
    String? model,
    String? provider,
    bool? isLoading,
    String? error,
  }) {
    return UsageState(
      items: items ?? this.items,
      costByProvider: costByProvider ?? this.costByProvider,
      costByModel: costByModel ?? this.costByModel,
      dailyCost: dailyCost ?? this.dailyCost,
      start: start ?? this.start,
      end: end ?? this.end,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UsageBloc extends Bloc<UsageEvent, UsageState> {
  final ObjectBoxStore _store;

  UsageBloc(this._store) : super(UsageState()) {
    on<LoadUsage>(_onLoadUsage);
  }

  Future<void> _onLoadUsage(LoadUsage event, Emitter<UsageState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final box = _store.store.box<ChatMessageEntity>();
      var messages = box.getAll();

      // Apply filtering
      if (event.start != null) {
        messages = messages.where((m) => m.timestamp.isAfter(event.start!)).toList();
      }
      if (event.end != null) {
        messages = messages.where((m) => m.timestamp.isBefore(event.end!)).toList();
      }
      if (event.model != null) {
        messages = messages.where((m) => m.session.target?.selectedModel == event.model).toList();
      }
      if (event.provider != null) {
        messages = messages.where((m) => m.session.target?.selectedProvider == event.provider).toList();
      }

      // Aggregate data
      final Map<String, double> byProvider = {};
      final Map<String, double> byModel = {};
      final Map<String, double> daily = {};

      for (final m in messages) {
        final cost = m.estimatedCost ?? 0.0;
        final provider = m.session.target?.selectedProvider ?? 'unknown';
        final model = m.session.target?.selectedModel ?? 'unknown';
        final day = DateFormat('yyyy-MM-dd').format(m.timestamp);

        byProvider[provider] = (byProvider[provider] ?? 0.0) + cost;
        byModel[model] = (byModel[model] ?? 0.0) + cost;
        daily[day] = (daily[day] ?? 0.0) + cost;
      }

      emit(state.copyWith(
        items: messages,
        costByProvider: byProvider,
        costByModel: byModel,
        dailyCost: daily,
        start: event.start,
        end: event.end,
        model: event.model,
        provider: event.provider,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }
}
