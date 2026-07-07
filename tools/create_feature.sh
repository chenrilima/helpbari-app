#!/bin/bash

FEATURE=$1
SINGULAR=$2

if [ -z "$FEATURE" ] || [ -z "$SINGULAR" ]; then
  echo "Uso: ./tools/create_feature.sh <feature_plural> <feature_singular>"
  echo "Exemplo: ./tools/create_feature.sh appointments appointment"
  exit 1
fi

BASE="lib/features/$FEATURE"

mkdir -p "$BASE/domain/entities"
mkdir -p "$BASE/domain/value_objects"
mkdir -p "$BASE/domain/models"
mkdir -p "$BASE/domain/repositories"
mkdir -p "$BASE/domain/usecases"

mkdir -p "$BASE/data/repositories"

mkdir -p "$BASE/presentation/models"
mkdir -p "$BASE/presentation/pages"
mkdir -p "$BASE/presentation/widgets"
mkdir -p "$BASE/presentation/providers"
mkdir -p "$BASE/presentation/states"
mkdir -p "$BASE/presentation/viewmodels"

touch "$BASE/domain/entities/$SINGULAR.dart"
touch "$BASE/domain/entities/entities.dart"

touch "$BASE/domain/value_objects/value_objects.dart"

touch "$BASE/domain/models/${SINGULAR}_summary.dart"

touch "$BASE/domain/repositories/${SINGULAR}_repository.dart"
touch "$BASE/domain/repositories/repositories.dart"

touch "$BASE/domain/usecases/${SINGULAR}_use_cases.dart"
touch "$BASE/domain/usecases/use_cases.dart"

touch "$BASE/data/repositories/fake_${SINGULAR}_repository.dart"

touch "$BASE/presentation/models/create_${SINGULAR}_form.dart"

touch "$BASE/presentation/providers/${SINGULAR}_use_cases_provider.dart"
touch "$BASE/presentation/providers/${SINGULAR}_view_model_provider.dart"

touch "$BASE/presentation/states/${SINGULAR}_state.dart"
touch "$BASE/presentation/viewmodels/${SINGULAR}_view_model.dart"

touch "$BASE/presentation/pages/${FEATURE}_page.dart"
touch "$BASE/presentation/pages/register_${SINGULAR}_page.dart"

touch "$BASE/presentation/widgets/${SINGULAR}_tile.dart"
touch "$BASE/presentation/widgets/${SINGULAR}_summary_card.dart"

echo "Feature criada com sucesso:"
echo "$BASE"