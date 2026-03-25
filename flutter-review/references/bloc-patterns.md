# BLoC Pattern — Best Practices

## Arquitetura BLoC/Cubit

```
┌─────────────┐    ┌──────────┐    ┌──────────────┐
│   Widget     │───→│  BLoC/   │───→│  Repository  │
│  (UI Layer)  │←───│  Cubit   │←───│  (Data Layer)│
│              │    │          │    │              │
│  BlocBuilder │    │  States  │    │  API Client  │
│  BlocListener│    │  Events  │    │  Local DB    │
└─────────────┘    └──────────┘    └──────────────┘
```

## Cubit vs BLoC — Quando usar qual

| Critério | Cubit | BLoC |
|----------|-------|------|
| Complexidade | Simples (funções) | Complexa (eventos) |
| Traceability | Baixa | Alta (cada evento é rastreável) |
| Testabilidade | Boa | Excelente (testar eventos) |
| Boilerplate | Menos | Mais |
| Quando usar | CRUD simples, telas de formulário | Fluxos complexos, multi-step, real-time |

## Cubit — Pattern Correto

```dart
// ✅ State imutável com copyWith
class RefuelingState extends Equatable {
  final List<Refueling> refuelings;
  final bool isLoading;
  final String? errorMessage;
  final RefuelingFilter filter;

  const RefuelingState({
    this.refuelings = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filter = const RefuelingFilter(),
  });

  RefuelingState copyWith({
    List<Refueling>? refuelings,
    bool? isLoading,
    String? errorMessage,
    RefuelingFilter? filter,
  }) {
    return RefuelingState(
      refuelings: refuelings ?? this.refuelings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [refuelings, isLoading, errorMessage, filter];
}

// ✅ Cubit com error handling
class RefuelingCubit extends Cubit<RefuelingState> {
  final RefuelingRepository _repository;

  RefuelingCubit(this._repository) : super(const RefuelingState());

  Future<void> loadRefuelings() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final refuelings = await _repository.getRefuelings(state.filter);
      emit(state.copyWith(refuelings: refuelings, isLoading: false));
    } on NetworkException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Sem conexão: ${e.message}',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erro inesperado. Tente novamente.',
      ));
    }
  }

  void updateFilter(RefuelingFilter filter) {
    emit(state.copyWith(filter: filter));
    loadRefuelings();
  }
}
```

## BLoC — Pattern Correto

```dart
// ✅ Sealed class para eventos
sealed class BillingEvent extends Equatable {
  const BillingEvent();
}

class LoadBillingCycles extends BillingEvent {
  final String stationId;
  const LoadBillingCycles(this.stationId);
  
  @override
  List<Object> get props => [stationId];
}

class ApproveCycle extends BillingEvent {
  final String cycleId;
  const ApproveCycle(this.cycleId);
  
  @override
  List<Object> get props => [cycleId];
}

// ✅ Sealed class para estados
sealed class BillingState extends Equatable {
  const BillingState();
}

class BillingInitial extends BillingState {
  @override
  List<Object> get props => [];
}

class BillingLoading extends BillingState {
  @override
  List<Object> get props => [];
}

class BillingLoaded extends BillingState {
  final List<BillingCycle> cycles;
  const BillingLoaded(this.cycles);
  
  @override
  List<Object> get props => [cycles];
}

class BillingError extends BillingState {
  final String message;
  const BillingError(this.message);
  
  @override
  List<Object> get props => [message];
}

// ✅ BLoC com event handlers
class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final BillingRepository _repository;

  BillingBloc(this._repository) : super(BillingInitial()) {
    on<LoadBillingCycles>(_onLoadCycles);
    on<ApproveCycle>(_onApproveCycle);
  }

  Future<void> _onLoadCycles(
    LoadBillingCycles event,
    Emitter<BillingState> emit,
  ) async {
    emit(BillingLoading());
    try {
      final cycles = await _repository.getCycles(event.stationId);
      emit(BillingLoaded(cycles));
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> _onApproveCycle(
    ApproveCycle event,
    Emitter<BillingState> emit,
  ) async {
    // Manter estado atual enquanto processa
    final currentState = state;
    try {
      await _repository.approveCycle(event.cycleId);
      if (currentState is BillingLoaded) {
        // Reload
        add(LoadBillingCycles(currentState.cycles.first.stationId));
      }
    } catch (e) {
      emit(BillingError('Falha ao aprovar ciclo: ${e.toString()}'));
    }
  }
}
```

## Anti-Patterns

```dart
// ❌ State mutável
class BadState {
  List<Item> items = []; // Mutável!
}

// ❌ Lógica de negócio no Widget
onPressed: () {
  final price = quantity * unitPrice * (1 - discount); // ❌ Deveria estar no BLoC
  setState(() => total = price);
}

// ❌ BLoC que conhece o Widget
class BadBloc extends Cubit<State> {
  final BuildContext context; // ❌ NUNCA!
  BadBloc(this.context) : super(State());
}

// ❌ Emit após dispose
Future<void> loadData() async {
  final data = await repo.getData();
  emit(Loaded(data)); // ❌ Pode crashar se BLoC já foi closed
}

// ✅ Verificar antes de emit
Future<void> loadData() async {
  final data = await repo.getData();
  if (!isClosed) {
    emit(Loaded(data));
  }
}
```

## Checklist

- [ ] States são imutáveis (Equatable + const constructor)
- [ ] States têm copyWith para updates parciais
- [ ] Error handling em todo async operation
- [ ] BLoC nunca recebe BuildContext
- [ ] Verificar `isClosed` antes de emit em operações longas
- [ ] Repository injetado (não instanciado dentro do BLoC)
- [ ] BlocProvider no ponto mais alto necessário da árvore
- [ ] BlocBuilder com buildWhen para otimizar rebuilds
