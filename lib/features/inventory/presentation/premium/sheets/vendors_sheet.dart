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
import 'package:solar_icons/solar_icons.dart';

void showVendorsSheet(BuildContext context) {
  context.read<VendorsBloc>().add(const OnVendorsStarted());
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<VendorsBloc>(),
      child: const _VendorsSheet(),
    ),
  );
}

class _VendorsSheet extends StatelessWidget {
  const _VendorsSheet();

  void _addVendor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<VendorsBloc>(),
        child: const _VendorFormSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<VendorsBloc, VendorsState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == VendorsSubmitStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor saved')),
          );
        } else if (state.submitStatus == VendorsSubmitStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.submitError ?? 'Failed to save vendor'),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                        'Vendors',
                        style: AppTextStyles.bs400(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _addVendor(context),
                        icon: const Icon(SolarIconsOutline.addCircle,
                            size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                            foregroundColor: goldDeep),
                      ),
                      IconButton(
                        icon: Icon(SolarIconsOutline.closeCircle,
                            color: colors.textSecondary),
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
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (state.vendors.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(SolarIconsOutline.shop,
                                  size: 48,
                                  color: colors.textSecondary
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No vendors yet',
                                style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => _addVendor(context),
                                style: TextButton.styleFrom(
                                    foregroundColor: goldDeep),
                                child: const Text('Add your first vendor'),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppDims.s4),
                        itemCount: state.vendors.length,
                        separatorBuilder: (_, i) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final vendor = state.vendors[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  goldDeep.withValues(alpha: 0.10),
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
                            title: Text(
                              vendor.name,
                              style: AppTextStyles.bs300(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            subtitle: vendor.phone != null
                                ? Text(
                                    vendor.phone!,
                                    style: AppTextStyles.bs200(context)
                                        .copyWith(
                                            color: colors.textSecondary),
                                  )
                                : null,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<VendorsBloc>(),
                                      child: _VendorFormSheet(
                                          existing: vendor),
                                    ),
                                  );
                                } else if (value == 'deactivate') {
                                  context.read<VendorsBloc>().add(
                                        OnVendorUpdate(
                                          vendor.id,
                                          const UpdateVendorRequestDto(
                                              isActive: false),
                                        ),
                                      );
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'deactivate',
                                  child: Text('Deactivate'),
                                ),
                              ],
                            ),
                          );
                        },
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppDims.s4),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Vendor' : 'Add Vendor',
                style: AppTextStyles.bs400(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDims.s3),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppDims.s2),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppDims.s2),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppDims.s2),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
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
                    isEdit ? 'Save Changes' : 'Add Vendor',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
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
