import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/app_bottom_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/primary_sheet_button.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class EditProfileSheet extends StatefulWidget {
  final String fullName;
  final String email;
  final String bankakAccountNumber;

  const EditProfileSheet({
    super.key,
    required this.fullName,
    required this.email,
    required this.bankakAccountNumber,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _fullNameCtrl = TextEditingController(text: widget.fullName);
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    context.read<SettingsBloc>().add(
      OnUpdateProfile(
        dto: UpdateProfileRequestDto(
          fullName: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          bankakAccountNumber: widget.bankakAccountNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Edit Profile',
      subtitle: 'Update your name and contact information.',
      icon: SolarIconsOutline.user,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldLabel(
              label: 'Full Name',
              required: true,
            ),
            const SizedBox(height: AppDims.s1),
            AppFormField(
              controller: _fullNameCtrl,
              focusNode: _fullNameFocus,
              nextFocus: _emailFocus,
              hint: 'Owner full name',
              prefixIcon: SolarIconsOutline.user,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final text = value?.trim() ?? '';

                if (text.isEmpty) {
                  return 'Full name is required';
                }

                if (text.length < 2) {
                  return 'Name is too short';
                }

                return null;
              },
            ),

            const SizedBox(height: AppDims.s4),

            FieldLabel(
              label: 'Email',
            ),
            const SizedBox(height: AppDims.s1),
            AppFormField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              hint: 'email@example.com',
              prefixIcon: SolarIconsOutline.letter,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (value) {
                final text = value?.trim() ?? '';

                if (text.isEmpty) {
                  return null;
                }

                final isValid = RegExp(
                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                ).hasMatch(text);

                if (!isValid) {
                  return 'Enter a valid email';
                }

                return null;
              },
            ),

            const SizedBox(height: AppDims.s5),

            BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (prev, curr) {
                return prev.submitStatus != curr.submitStatus;
              },
              builder: (context, state) {
                return PrimarySheetButton(
                  label: 'Save Profile',
                  isLoading:
                  state.submitStatus == SettingsSubmitStatus.loading,
                  onPressed: _submit,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}