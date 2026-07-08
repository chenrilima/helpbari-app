import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    stdout.writeln(
      'Uso: dart run tools/create_feature.dart <plural> <singular>',
    );
    stdout.writeln('Exemplo: dart run tools/create_feature.dart exams exam');
    exit(1);
  }

  final feature = args[0];
  final singular = args[1];

  final pascalFeature = _toPascalCase(singular);
  final base = 'lib/features/$feature';

  final files = <String, String>{
    '$base/domain/entities/$singular.dart': _entityTemplate(pascalFeature),
    '$base/domain/entities/entities.dart': "export '$singular.dart';\n",
    '$base/README.md': _featureReadmeTemplate(feature, pascalFeature),
    '$base/CHANGELOG.md': _featureChangelogTemplate(pascalFeature),
    '$base/feature.md': _featureDocTemplate(feature, pascalFeature),

    '$base/domain/repositories/${singular}_repository.dart':
        _repositoryTemplate(pascalFeature),
    '$base/domain/repositories/repositories.dart':
        "export '${singular}_repository.dart';\n",

    '$base/domain/usecases/${singular}_use_cases.dart': _useCasesTemplate(
      pascalFeature,
      singular,
    ),
    '$base/domain/usecases/use_cases.dart':
        "export '${singular}_use_cases.dart';\n",

    '$base/data/repositories/fake_${singular}_repository.dart':
        _fakeRepositoryTemplate(pascalFeature),

    '$base/presentation/states/${singular}_state.dart': _stateTemplate(
      pascalFeature,
      singular,
    ),
    '$base/presentation/providers/${singular}_use_cases_provider.dart':
        _useCasesProviderTemplate(pascalFeature, feature, singular),
    '$base/presentation/providers/${singular}_view_model_provider.dart':
        _viewModelProviderTemplate(pascalFeature, singular),
    '$base/presentation/viewmodels/${singular}_view_model.dart':
        _viewModelTemplate(pascalFeature, singular),

    '$base/presentation/pages/${feature}_page.dart': _pageTemplate(
      pascalFeature,
      feature,
      singular,
    ),
    '$base/presentation/pages/register_${singular}_page.dart':
        _registerPageTemplate(pascalFeature),
    '$base/presentation/widgets/${singular}_tile.dart': _tileTemplate(
      pascalFeature,
    ),
    '$base/presentation/widgets/${singular}_summary_card.dart':
        _summaryCardTemplate(pascalFeature),
    '$base/domain/value_objects/value_objects.dart':
        "export '${singular}_name.dart';\n"
        "export '${singular}_date.dart';\n",

    '$base/domain/value_objects/${singular}_name.dart':
        _nameValueObjectTemplate(pascalFeature),

    '$base/domain/value_objects/${singular}_date.dart':
        _dateValueObjectTemplate(pascalFeature),
  };

  for (final entry in files.entries) {
    final file = File(entry.key);
    file.parent.createSync(recursive: true);

    if (file.existsSync()) {
      stdout.writeln('Ignorado, já existe: ${entry.key}');
      continue;
    }

    file.writeAsStringSync(entry.value);
    stdout.writeln('Criado: ${entry.key}');
  }

  stdout.writeln('\nFeature criada com sucesso: $feature');
}

String _toPascalCase(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();
}

String _entityTemplate(String name) {
  return '''
import '../../../../core/domain/entity.dart';

class $name extends Entity {
  const $name({
    required this.id,
  });

  @override
  final String id;
}
''';
}

String _repositoryTemplate(String name) {
  return '''
import '../entities/entities.dart';

abstract interface class ${name}Repository {
  Future<List<$name>> getAll();

  Future<void> save($name item);

  Future<void> update($name item);

  Future<void> delete(String id);
}
''';
}

String _fakeRepositoryTemplate(String name) {
  return '''
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class Fake${name}Repository implements ${name}Repository {
  final List<$name> _items = [];

  @override
  Future<List<$name>> getAll() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<void> save($name item) async {
    _items.add(item);
  }

  @override
  Future<void> update($name item) async {
    final index = _items.indexWhere((element) => element.id == item.id);

    if (index == -1) return;

    _items[index] = item;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}
''';
}

String _useCasesTemplate(String name, String singular) {
  return '''
import '../entities/entities.dart';
import '../repositories/repositories.dart';

class ${name}UseCases {
  const ${name}UseCases(this._repository);

  final ${name}Repository _repository;

  Future<List<$name>> getAll() {
    return _repository.getAll();
  }

  Future<void> save($name item) {
    return _repository.save(item);
  }

  Future<void> update($name item) {
    return _repository.update(item);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }
}
''';
}

String _stateTemplate(String name, String singular) {
  return '''
import '../../domain/entities/entities.dart';

class ${name}State {
  const ${name}State({
    this.items = const [],
    this.isLoading = false,
  });

  final List<$name> items;
  final bool isLoading;

  bool get hasItems => items.isNotEmpty;
  $name? get latestItem =>
    items.isEmpty ? null : items.first;

  ${name}State copyWith({
    List<$name>? items,
    bool? isLoading,
  }) {
    return ${name}State(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
''';
}

String _useCasesProviderTemplate(String name, String feature, String singular) {
  return '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_${singular}_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final ${singular}RepositoryProvider = Provider<${name}Repository>((ref) {
  return Fake${name}Repository();
});

final ${singular}UseCasesProvider = Provider<${name}UseCases>((ref) {
  return ${name}UseCases(
    ref.read(${singular}RepositoryProvider),
  );
});
''';
}

String _viewModelProviderTemplate(String name, String singular) {
  return '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/${singular}_state.dart';
import '../viewmodels/${singular}_view_model.dart';

final ${singular}ViewModelProvider =
    NotifierProvider<${name}ViewModel, ${name}State>(
  ${name}ViewModel.new,
);
''';
}

String _viewModelTemplate(String name, String singular) {
  return '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/use_cases.dart';
import '../providers/${singular}_use_cases_provider.dart';
import '../states/${singular}_state.dart';

class ${name}ViewModel extends Notifier<${name}State> {
  late final ${name}UseCases _useCases;

  @override
  ${name}State build() {
    _useCases = ref.read(${singular}UseCasesProvider);

    return const ${name}State();
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true);

    final items = await _useCases.getAll();

    state = state.copyWith(
      items: items,
      isLoading: false,
    );
  }
}
''';
}

String _pageTemplate(String name, String feature, String singular) {
  return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../providers/${singular}_view_model_provider.dart';

class ${name}sPage extends ConsumerStatefulWidget {
  const ${name}sPage({super.key});

  @override
  ConsumerState<${name}sPage> createState() => _${name}sPageState();
}

class _${name}sPageState extends ConsumerState<${name}sPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(${singular}ViewModelProvider.notifier).loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(${singular}ViewModelProvider);

    return HBPage(
      children: [
        HBText(
          '$name',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const HBGap.xl(),
        if (!state.hasItems)
          const HBEmptyState(
            title: 'Nenhum item encontrado',
            description: 'Cadastre o primeiro item para começar.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const HBGap.md(),
            itemBuilder: (_, index) {
              final item = state.items[index];

              return HBCard(
                child: HBText(item.id),
              );
            },
          ),
      ],
    );
  }
}
''';
}

String _registerPageTemplate(String name) {
  return '''
import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class Register${name}Page extends StatelessWidget {
  const Register${name}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return HBPage(
      children: [
        HBText(
          'Cadastrar $name',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
''';
}

String _tileTemplate(String name) {
  return '''
import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class ${name}Tile extends StatelessWidget {
  const ${name}Tile({
    required this.item,
    super.key,
  });

  final $name item;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: HBText(item.id),
    );
  }
}
''';
}

String _summaryCardTemplate(String name) {
  return '''
import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ${name}SummaryCard extends StatelessWidget {
  const ${name}SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const HBMetricCard(
      title: '$name',
      value: 'Em breve',
    );
  }
}
''';
}

String _featureReadmeTemplate(String feature, String name) {
  return '''
# $name Feature

Feature gerada automaticamente para o módulo `$feature`.

## Responsabilidade

Esta feature deve concentrar regras, telas e componentes relacionados a `$name`.

## Estrutura

- domain
- data
- presentation

## Fluxo padrão

UI
↓
ViewModel
↓
UseCases
↓
Repository
''';
}

String _featureChangelogTemplate(String name) {
  return '''
# $name Changelog

## Unreleased

- Estrutura inicial da feature criada.
''';
}

String _featureDocTemplate(String feature, String name) {
  return '''
# $name

## Objetivo

Descrever a responsabilidade da feature `$feature`.

## Regras de negócio

- Adicionar regras conforme a feature evoluir.

## Integração com Home

- Definir se a feature será exibida na Home.
- Definir resumo, cards e ações rápidas.

## Integração futura com Supabase

- Definir tabela.
- Definir campos.
- Definir políticas RLS.
''';
}

String _nameValueObjectTemplate(String name) {
  return '''
class ${name}Name {
  const ${name}Name._(
    this.value,
  );

  final String value;

  static ${name}Name? create(
    String value,
  ) {
    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return null;
    }

    return ${name}Name._(
      trimmed,
    );
  }

  @override
  String toString() {
    return value;
  }
}
''';
}

String _dateValueObjectTemplate(String name) {
  return '''
class ${name}Date {
  const ${name}Date(
    this.value,
  );

  final DateTime value;

  String get formatted {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    return '\$day/\$month/\$year';
  }

  @override
  String toString() {
    return formatted;
  }
}
''';
}
