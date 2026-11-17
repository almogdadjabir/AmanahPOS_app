import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/features/sync/presentation/widgets/catalog_sync_pill.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/update_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

void showVendorsSheet(BuildContext context) {
  context.read<VendorsBloc>().add(const OnVendorsStarted());
  showAdaptivePanel<void>(
    context,
    builder: (_) => BlocProvider.value(
      value: context.read<VendorsBloc>(),
      child: const _VendorsSheet(),
    ),
  );
}

/// Opens the add / edit vendor form. [bloc] defaults to the one in
/// [context] (the pending-sync screen passes its own for "Edit and retry").
/// Completes with true when the user submitted (the sheet closes right
/// after dispatching the save, which may still be running: see
/// [VendorsState.submitStatus]).
Future<bool?> showVendorFormSheet(
  BuildContext context, {
  VendorData? existing,
  VendorsBloc? bloc,
}) => showAdaptivePanel<bool>(
  context,
  builder: (_) => BlocProvider.value(
    value: bloc ?? context.read<VendorsBloc>(),
    child: _VendorFormSheet(existing: existing),
  ),
);

class _VendorsSheet extends StatelessWidget {
  const _VendorsSheet();

  void _addVendor(BuildContext context) => showVendorFormSheet(context);

  /// Pull to refresh: re-read SQLite and ask the server for changes.
  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<VendorsBloc>()
      ..add(const OnVendorsStarted())
      ..add(const OnVendorsSyncRequested());
    try {
      await bloc.stream
          .firstWhere((s) => s.status != VendorsStatus.loading)
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // An unchanged list emits nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Vendor writes are owner/manager only (BE `forbidden` otherwise).
    final canEdit = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.canEditCatalog,
    );
    return BlocListener<VendorsBloc, VendorsState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == VendorsSubmitStatus.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr.invVendorSaved)));
        } else if (state.submitStatus == VendorsSubmitStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.submitError ?? context.tr.invVendorFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                  child: Row(
                    children: [
                      Text(
                        context.tr.invVendors,
                        style: AppTextStyles.bs400(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (canEdit)
                        TextButton.icon(
                          key: const ValueKey('vendors-add'),
                          onPressed: () => _addVendor(context),
                          icon: const Icon(
                            PhosphorIconsRegular.plusCircle,
                            size: 18,
                          ),
                          label: Text(context.tr.add),
                          style: TextButton.styleFrom(
                            foregroundColor: goldDeep,
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          PhosphorIconsRegular.xCircle,
                          color: colors.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: BlocBuilder<VendorsBloc, VendorsState>(
                    builder: (context, state) {
                      if (state.status == VendorsStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.vendors.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIconsRegular.storefront,
                                size: 48,
                                color: colors.textSecondary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr.invNoVendorsYet,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (canEdit)
                                TextButton(
                                  onPressed: () => _addVendor(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: goldDeep,
                                  ),
                                  child: Text(context.tr.invAddFirstVendor),
                                ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => _refresh(context),
                        child: ListView.separated(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppDims.s4),
                          itemCount: state.vendors.length,
                          separatorBuilder: (_, i) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final vendor = state.vendors[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: goldDeep.withValues(
                                  alpha: 0.10,
                                ),
                                child: Text(
                                  vendor.name.isNotEmpty
                                      ? vendor.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: goldDeep,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      vendor.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bs300(context)
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                    ),
                                  ),
                                  if (state.syncMarks.markOf(vendor.id) !=
                                      CatalogSyncMark.synced) ...[
                                    const SizedBox(width: 6),
                                    CatalogSyncPill(
                                      mark: state.syncMarks.markOf(vendor.id),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: vendor.phone != null
                                  ? Text(
                                      vendor.phone!,
                                      style: AppTextStyles.bs200(
                                        context,
                                      ).copyWith(color: colors.textSecondary),
                                    )
                                  : null,
                              trailing: !canEdit
                                  ? null
                                  : PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          showVendorFormSheet(
                                            context,
                                            existing: vendor,
                                          );
                                        } else if (value == 'deactivate') {
                                          context.read<VendorsBloc>().add(
                                            OnVendorUpdate(
                                              vendor.id,
                                              const UpdateVendorRequestDto(
                                                isActive: false,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(context.tr.edit),
                                        ),
                                        PopupMenuItem(
                                          value: 'deactivate',
                                          child: Text(
                                            context.tr.invVendorDeactivate,
                                          ),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VendorFormSheet extends StatefulWidget {
  final VendorData? existing;
  const _VendorFormSheet({this.existing});

  @override
  State<_VendorFormSheet> createState() => _VendorFormSheetState();
}

class _VendorFormSheetState extends State<_VendorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name);
    _phone = TextEditingController(text: widget.existing?.phone);
    _email = TextEditingController(text: widget.existing?.email);
    _notes = TextEditingController(text: widget.existing?.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.existing != null) {
      context.read<VendorsBloc>().add(
        OnVendorUpdate(
          widget.existing!.id,
          UpdateVendorRequestDto(
            name: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          ),
        ),
      );
    } else {
      context.read<VendorsBloc>().add(
        OnVendorCreate(
          CreateVendorRequestDto(
            name: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          ),
        ),
      );
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppDims.s4),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? context.tr.invEditVendor : context.tr.invAddVendor,
                style: AppTextStyles.bs400(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDims.s3),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: context.tr.invVendorNameLabel,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr.nameRequired
                    : null,
              ),
              const SizedBox(height: AppDims.s2),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(labelText: context.tr.fieldPhone),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppDims.s2),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: context.tr.fieldEmail),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppDims.s2),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(labelText: context.tr.fieldNotes),
                maxLines: 2,
              ),
              const SizedBox(height: AppDims.s4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                  ),
                  child: Text(
                    isEdit ? context.tr.saveChanges : context.tr.invAddVendor,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s2),
            ],
          ),
        ),
      ),
    );
  }
}
