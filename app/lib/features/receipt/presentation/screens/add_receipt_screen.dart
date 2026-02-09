import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../../domain/services/image_pipeline_service.dart';
import '../../domain/services/ocr_service.dart';
import '../bloc/add_receipt_bloc.dart';
import '../bloc/add_receipt_event.dart';
import '../bloc/add_receipt_state.dart';
import '../widgets/capture_option_sheet.dart';
import '../widgets/image_preview_strip.dart';
import '../widgets/ocr_progress_indicator.dart';
import '../widgets/receipt_field_editors.dart';

/// Full-screen receipt capture flow driven by [AddReceiptBloc].
///
/// Accepts an optional [initialOption] from the [CaptureOptionSheet] to auto-
/// trigger a capture source on mount.
class AddReceiptScreen extends StatelessWidget {
  const AddReceiptScreen({super.key, this.initialOption});

  final CaptureOption? initialOption;

  static const _userId = 'demo-user';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = AddReceiptBloc(
          imagePipelineService: GetIt.I<ImagePipelineService>(),
          ocrService: GetIt.I<OcrService>(),
          receiptRepository: GetIt.I<ReceiptRepository>(),
        );
        // Auto-trigger the chosen capture source.
        if (initialOption != null) {
          switch (initialOption!) {
            case CaptureOption.camera:
              bloc.add(const CaptureFromCamera());
            case CaptureOption.gallery:
              bloc.add(const ImportFromGallery());
            case CaptureOption.files:
              bloc.add(const ImportFromFiles());
          }
        }
        return bloc;
      },
      child: const _AddReceiptBody(),
    );
  }
}

class _AddReceiptBody extends StatelessWidget {
  const _AddReceiptBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<AddReceiptBloc, AddReceiptState>(
      listener: (context, state) {
        if (state is AddReceiptSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.receiptSaved)),
          );
          Navigator.of(context).pop();
        }
        if (state is AddReceiptError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.captureReceipt),
            actions: _buildAppBarActions(context, state, l10n),
          ),
          body: _buildBody(context, state, l10n),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    AddReceiptState state,
    AppLocalizations l10n,
  ) {
    final actions = <Widget>[];

    // Fast Save — available when images are ready.
    if (state is AddReceiptImagesReady ||
        state is AddReceiptFieldsReady) {
      actions.add(
        TextButton(
          onPressed: () => context
              .read<AddReceiptBloc>()
              .add(const FastSave(AddReceiptScreen._userId)),
          child: Text(
            l10n.fastSave,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return actions;
  }

  Widget _buildBody(
    BuildContext context,
    AddReceiptState state,
    AppLocalizations l10n,
  ) {
    return switch (state) {
      AddReceiptInitial() => _InitialView(l10n: l10n),
      AddReceiptCapturing() => const Center(child: CircularProgressIndicator()),
      AddReceiptImagesReady() =>
        _ImagesReadyView(state: state, l10n: l10n),
      AddReceiptProcessingOcr() =>
        _OcrProcessingView(state: state),
      AddReceiptFieldsReady() =>
        _FieldsReadyView(state: state, l10n: l10n),
      AddReceiptSaving() =>
        Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            AppSpacing.verticalGapMd,
            Text(l10n.savingReceipt),
          ],
        )),
      AddReceiptSaved() => const SizedBox.shrink(),
      AddReceiptError() => _InitialView(l10n: l10n),
    };
  }
}

// =============================================================================
// Initial — show capture options
// =============================================================================

class _InitialView extends StatelessWidget {
  const _InitialView({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo,
              size: 64,
              color: AppColors.textLight,
            ),
            AppSpacing.verticalGapMd,
            Text(
              l10n.captureReceipt,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
            ),
            AppSpacing.verticalGapSm,
            Text(
              l10n.captureReceiptDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalGapLg,
            _CaptureButton(
              icon: Icons.camera_alt,
              label: l10n.camera,
              onTap: () => context
                  .read<AddReceiptBloc>()
                  .add(const CaptureFromCamera()),
            ),
            AppSpacing.verticalGapSm,
            _CaptureButton(
              icon: Icons.photo_library,
              label: l10n.gallery,
              onTap: () => context
                  .read<AddReceiptBloc>()
                  .add(const ImportFromGallery()),
            ),
            AppSpacing.verticalGapSm,
            _CaptureButton(
              icon: Icons.file_present,
              label: l10n.files,
              onTap: () => context
                  .read<AddReceiptBloc>()
                  .add(const ImportFromFiles()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.primaryGreen),
          foregroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Images ready — preview strip + continue to OCR
// =============================================================================

class _ImagesReadyView extends StatelessWidget {
  const _ImagesReadyView({required this.state, required this.l10n});

  final AddReceiptImagesReady state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ImagePreviewStrip(
            images: state.images,
            onCrop: (index) => context
                .read<AddReceiptBloc>()
                .add(CropImage(index)),
            onDelete: (index) => context
                .read<AddReceiptBloc>()
                .add(RemoveImage(index)),
          ),
        ),
        Padding(
          padding: AppSpacing.screenPadding,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context
                  .read<AddReceiptBloc>()
                  .add(const ProcessOcr()),
              icon: const Icon(Icons.document_scanner),
              label: Text(l10n.continueToOcr),
            ),
          ),
        ),
        AppSpacing.verticalGapMd,
      ],
    );
  }
}

// =============================================================================
// OCR in progress
// =============================================================================

class _OcrProcessingView extends StatelessWidget {
  const _OcrProcessingView({required this.state});

  final AddReceiptProcessingOcr state;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: OcrProgressIndicator(
        status: OcrProgressStatus.extracting,
      ),
    );
  }
}

// =============================================================================
// Fields ready — form for editing extracted fields
// =============================================================================

class _FieldsReadyView extends StatefulWidget {
  const _FieldsReadyView({required this.state, required this.l10n});

  final AddReceiptFieldsReady state;
  final AppLocalizations l10n;

  @override
  State<_FieldsReadyView> createState() => _FieldsReadyViewState();
}

class _FieldsReadyViewState extends State<_FieldsReadyView> {
  late final TextEditingController _storeController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _storeController =
        TextEditingController(text: widget.state.storeName ?? '');
    _amountController = TextEditingController(
      text: widget.state.totalAmount?.toString() ?? '',
    );
    _notesController =
        TextEditingController(text: widget.state.notes ?? '');
  }

  @override
  void dispose() {
    _storeController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AddReceiptBloc>();
    final l10n = widget.l10n;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image strip (compact)
          SizedBox(
            height: 80,
            child: ImagePreviewStrip(
              images: widget.state.images,
              onCrop: (i) => bloc.add(CropImage(i)),
              onDelete: (i) => bloc.add(RemoveImage(i)),
            ),
          ),

          AppSpacing.verticalGapMd,

          // OCR confidence indicator
          if (widget.state.ocrResult != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high,
                      size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    'OCR confidence: ${(widget.state.ocrResult!.confidence * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

          StoreNameField(
            controller: _storeController,
            onChanged: (v) => bloc.add(UpdateField('storeName', v)),
          ),
          AppSpacing.verticalGapMd,

          PurchaseDateField(
            value: widget.state.purchaseDate,
            onChanged: (v) => bloc.add(UpdateField('purchaseDate', v)),
          ),
          AppSpacing.verticalGapMd,

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TotalAmountField(
                  controller: _amountController,
                  onChanged: (v) {
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed != null) {
                      bloc.add(UpdateField('totalAmount', parsed));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CurrencySelector(
                  value: widget.state.currency,
                  onChanged: (v) => bloc.add(UpdateField('currency', v)),
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapMd,

          WarrantyEditor(
            months: widget.state.warrantyMonths,
            onChanged: (v) => bloc.add(SetWarranty(v)),
          ),
          AppSpacing.verticalGapMd,

          NotesField(
            controller: _notesController,
            onChanged: (v) => bloc.add(UpdateField('notes', v)),
          ),
          AppSpacing.verticalGapLg,

          // Save button
          FilledButton.icon(
            onPressed: () => bloc.add(
              const SaveReceipt(AddReceiptScreen._userId),
            ),
            icon: const Icon(Icons.save),
            label: Text(l10n.save),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          AppSpacing.verticalGapLg,
        ],
      ),
    );
  }
}
