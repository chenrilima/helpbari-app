import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/media/media.dart';
import '../../../../design_system/design_system.dart';
import '../providers/profile_view_model_provider.dart';
import '../states/profile_state.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);

    ref.listen(profileViewModelProvider, (previous, next) {
      if (next.photoErrorMessage != null &&
          next.photoErrorMessage != previous?.photoErrorMessage) {
        HBSnackBar.error(context, message: next.photoErrorMessage!);
      } else if (previous?.photoStatus == ProfilePhotoStatus.uploading &&
          next.photoStatus == ProfilePhotoStatus.synced) {
        HBSnackBar.success(context, message: 'Foto de perfil atualizada.');
      } else if (previous?.photoStatus == ProfilePhotoStatus.removing &&
          next.photoStatus == ProfilePhotoStatus.none) {
        HBSnackBar.success(context, message: 'Foto de perfil removida.');
      }
    });

    if (state.isLoading) {
      return const HBPage(
        appBar: HBAppBar(title: 'Perfil'),
        children: [HBLoading(message: 'Carregando perfil...')],
      );
    }

    if (state.profile == null) {
      return HBPage(
        appBar: const HBAppBar(
          title: 'Perfil',
          subtitle: 'Suas informações pessoais',
        ),
        children: [
          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar o perfil',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: () =>
                  ref.read(profileViewModelProvider.notifier).loadProfile(),
            )
          else
            HBEmptyState(
              title: 'Complete seu perfil',
              description:
                  'Precisamos de algumas informações para personalizar sua jornada.',
              icon: AppIcons.profile,
              actionLabel: 'Completar perfil',
              onActionPressed: () {
                context.pushAndRefresh(
                  AppRoutes.completeProfile,
                  onRefresh: () {
                    return ref
                        .read(profileViewModelProvider.notifier)
                        .loadProfile();
                  },
                );
              },
            ),
        ],
      );
    }

    final profile = state.profile!;

    return HBLoadingOverlay(
      isLoading: state.isPhotoBusy,
      message: state.photoStatus == ProfilePhotoStatus.removing
          ? 'Removendo foto...'
          : 'Enviando foto...',
      child: HBPage(
        appBar: HBAppBar(
          title: 'Perfil',
          subtitle: 'Suas informações bariátricas',
          actions: [
            IconButton(
              tooltip: 'Editar perfil',
              onPressed: () => context.pushAndRefresh(
                AppRoutes.completeProfile,
                onRefresh: () =>
                    ref.read(profileViewModelProvider.notifier).loadProfile(),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Excluir perfil',
              onPressed: () async {
                final confirmed = await HBDialog.confirm(
                  context,
                  title: 'Excluir perfil?',
                  message:
                      'O perfil será removido deste aparelho e sincronizado quando houver conexão.',
                  confirmLabel: 'Excluir',
                  barrierDismissible: false,
                );
                if (confirmed == true) {
                  await ref
                      .read(profileViewModelProvider.notifier)
                      .deleteProfile();
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        children: [
          HBCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: state.cachedPhoto == null
                      ? null
                      : MemoryImage(state.cachedPhoto!.bytes),
                  child: state.cachedPhoto == null
                      ? const Icon(AppIcons.profile, size: 52)
                      : null,
                ),
                const HBGap.md(),
                Wrap(
                  spacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: state.isPhotoBusy
                          ? null
                          : () => _selectPhotoSource(context),
                      icon: const Icon(AppIcons.photo),
                      label: Text(
                        profile.photoStoragePath == null
                            ? 'Adicionar foto'
                            : 'Substituir foto',
                      ),
                    ),
                    if (state.photoStatus == ProfilePhotoStatus.failed &&
                        state.pendingPhoto != null)
                      TextButton.icon(
                        onPressed: () => ref
                            .read(profileViewModelProvider.notifier)
                            .uploadPendingPhoto(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    if (profile.photoStoragePath != null)
                      TextButton.icon(
                        onPressed: state.isPhotoBusy
                            ? null
                            : () => _confirmRemovePhoto(context),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remover'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'Nome',
            value: profile.name,
            icon: AppIcons.profile,
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'Altura',
            value: profile.height.formatted,
            icon: AppIcons.profile,
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'Peso inicial',
            value: profile.initialWeight.formatted,
            icon: AppIcons.weight,
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'Tipo de cirurgia',
            value: profile.surgeryType.label,
            icon: AppIcons.info,
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'Nascimento',
            value: AppDateFormatter.short(profile.birthDate.value),
            icon: AppIcons.info,
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'Data da cirurgia',
            value: AppDateFormatter.short(profile.surgeryDate.value),
            icon: AppIcons.info,
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'Idade',
            value: '${profile.age} anos',
            icon: AppIcons.profile,
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'Dias desde a cirurgia',
            value: '${profile.daysSinceSurgery} dias',
            icon: AppIcons.info,
          ),
          const HBGap.md(),
          HBMetricCard(
            title: 'IMC inicial',
            value: profile.initialBmi.formatted,
            icon: AppIcons.weight,
          ),
        ],
      ),
    );
  }

  Future<void> _selectPhotoSource(BuildContext context) async {
    final source = await HBDialog.custom<MediaSource>(
      context,
      title: 'Foto de perfil',
      content: const Text('Escolha de onde deseja selecionar a imagem.'),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, MediaSource.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Câmera'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context, MediaSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Galeria'),
        ),
      ],
    );
    if (source == null || !mounted) return;
    await ref.read(profileViewModelProvider.notifier).selectPhoto(source);
  }

  Future<void> _confirmRemovePhoto(BuildContext context) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Remover foto?',
      message: 'A foto será removida do seu perfil e do armazenamento privado.',
      confirmLabel: 'Remover',
    );
    if (confirmed != true || !mounted) return;
    await ref.read(profileViewModelProvider.notifier).removePhoto();
  }
}
