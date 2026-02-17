import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/storage/objectbox_entities.dart';
import '../../infrastructure/storage/objectbox_store.dart';
import '../../../objectbox.g.dart';
import '../../../core/providers/base_ai_provider.dart';
import '../../../core/utils/cost_estimator.dart';
import '../../infrastructure/providers/openai/openai_provider.dart';
import '../../infrastructure/providers/gemini/gemini_provider.dart';
import '../../infrastructure/storage/secure_storage_service.dart';

abstract class ChatEvent {}
class LoadSessions extends ChatEvent {}
class NewSession extends ChatEvent {
  final String providerId;
  final String model;
  NewSession({required this.providerId, required this.model});
}
class SelectSession extends ChatEvent {
  final int id;
  SelectSession(this.id);
}
class SendMessage extends ChatEvent {
  final String content;
  final String providerId;
  final String model;
  SendMessage({required this.content, required this.providerId, required this.model});
}
class RenameSession extends ChatEvent {
  final int id;
  final String newTitle;
  RenameSession(this.id, this.newTitle);
}

class ChatState {
  final List<ChatSessionEntity> sessions;
  final ChatSessionEntity? currentSession;
  final bool isStreaming;
  final String partialResponse;

  ChatState({
    this.sessions = const [],
    this.currentSession,
    this.isStreaming = false,
    this.partialResponse = '',
  });

  ChatState copyWith({
    List<ChatSessionEntity>? sessions,
    ChatSessionEntity? currentSession,
    bool? isStreaming,
    String? partialResponse,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      isStreaming: isStreaming ?? this.isStreaming,
      partialResponse: partialResponse ?? this.partialResponse,
    );
  }
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ObjectBoxStore _store;
  final SecureStorageService _secureStorage;
  final List<BaseAIProvider> _providers = [
    OpenAIProvider(),
    GeminiProvider(),
  ];

  ChatBloc(this._store, this._secureStorage) : super(ChatState()) {
    on<LoadSessions>(_onLoadSessions);
    on<NewSession>(_onNewSession);
    on<SelectSession>(_onSelectSession);
    on<SendMessage>(_onSendMessage);
    on<RenameSession>(_onRenameSession);
  }

  void _onRenameSession(RenameSession event, Emitter<ChatState> emit) {
    final box = _store.store.box<ChatSessionEntity>();
    final session = box.get(event.id);
    if (session != null) {
      session.title = event.newTitle;
      box.put(session);
      add(LoadSessions());
    }
  }

  void _onLoadSessions(LoadSessions event, Emitter<ChatState> emit) {
    final box = _store.store.box<ChatSessionEntity>();
    final sessions = box.getAll();
    emit(state.copyWith(sessions: sessions));
  }

  void _onNewSession(NewSession event, Emitter<ChatState> emit) {
    final session = ChatSessionEntity(
      selectedModel: event.model,
      selectedProvider: event.providerId,
    );
    _store.store.box<ChatSessionEntity>().put(session);
    add(LoadSessions());
    add(SelectSession(session.id));
  }

  void _onSelectSession(SelectSession event, Emitter<ChatState> emit) {
    final box = _store.store.box<ChatSessionEntity>();
    final session = box.get(event.id);
    emit(state.copyWith(currentSession: session));
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state.currentSession == null) return;
    
    final provider = _providers.firstWhere((p) => p.id == event.providerId);
    final apiKey = await _secureStorage.getApiKey(event.providerId);
    
    if (apiKey == null) return;

    final userTokens = CostEstimator.estimateTokens(event.content);
    final userCost = CostEstimator.estimateCost(
      inputTokens: userTokens,
      outputTokens: 0,
      model: event.model,
    );

    final userMessage = ChatMessageEntity(
      content: event.content,
      role: 'user',
      estimatedTokens: userTokens,
      estimatedCost: userCost,
    );
    state.currentSession!.messages.add(userMessage);
    _store.store.box<ChatSessionEntity>().put(state.currentSession!);

    emit(state.copyWith(isStreaming: true, partialResponse: ''));

    final history = state.currentSession!.messages.map((m) => ChatMessage(
      content: m.content,
      role: m.role == 'user' ? MessageRole.user : MessageRole.assistant,
    )).toList();

    String fullResponse = '';
    
    try {
      final stream = provider.sendMessageStream(
        prompt: event.content,
        history: history,
        model: event.model,
        apiKey: apiKey,
      );

      await for (final chunk in stream) {
        fullResponse += chunk;
        emit(state.copyWith(partialResponse: fullResponse));
      }
    } catch (e) {
      fullResponse = "Error: $e";
      emit(state.copyWith(partialResponse: fullResponse));
    }

    final assistantTokens = CostEstimator.estimateTokens(fullResponse);
    final assistantCost = CostEstimator.estimateCost(
      inputTokens: 0,
      outputTokens: assistantTokens,
      model: event.model,
    );

    final assistantMessage = ChatMessageEntity(
      content: fullResponse,
      role: 'assistant',
      estimatedTokens: assistantTokens,
      estimatedCost: assistantCost,
    );
    state.currentSession!.messages.add(assistantMessage);
    _store.store.box<ChatSessionEntity>().put(state.currentSession!);

    emit(state.copyWith(isStreaming: false, partialResponse: ''));
    add(LoadSessions());
  }
}
