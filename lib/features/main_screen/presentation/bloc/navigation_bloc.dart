import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/navigation_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final AuthBloc _authBloc;
  late final StreamSubscription<AuthState> _authSub;

  bool _ownerRedirectDone = false;

  NavigationBloc({required AuthBloc authBloc})
      : _authBloc = authBloc,
        super(NavigationState.initial()) {
    on<NavigationFeatureSelected>(_onFeatureSelected);
    on<NavigationPermissionsChanged>(_onPermissionsChanged);
    on<NavigationReset>(_onReset);
    on<SetMenuOpenEvent>(_onSetMenuOpen);

    // ── Subscribe to AuthBloc directly ────────────────────────────────────
    // Every AuthState emission is evaluated here, so NavigationBloc is always
    // in sync regardless of widget lifecycle, listener ordering, or cold-start.
    _authSub = _authBloc.stream.listen(_onAuthStateChanged);

    // ── Seed from current AuthBloc state immediately ──────────────────────
    // Handles the case where AuthBloc already has a valid state before this
    // bloc is created (e.g. BlocProvider.create called after login).
    _syncFromAuthState(_authBloc.state);
  }

  // ── Auth state handler (runs on every AuthBloc emission) ──────────────────

  void _onAuthStateChanged(AuthState authState) {
    // Logout: isLoggedIn flipped to false → full reset.
    if (!authState.isLoggedIn && state.permissions != AppPermissions.none) {
      add(const NavigationReset());
      return;
    }

    // Permissions changed (login, business loaded, role switch).
    if (authState.permissions != state.permissions) {
      add(NavigationPermissionsChanged(authState.permissions));
    }
  }

  void _syncFromAuthState(AuthState authState) {
    if (authState.permissions != AppPermissions.none) {
      add(NavigationPermissionsChanged(authState.permissions));
    }
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  void _onFeatureSelected(
      NavigationFeatureSelected event,
      Emitter<NavigationState> emit,
      ) {
    if (!state.permissions.allows(event.feature)) return;
    emit(state.copyWith(currentFeature: event.feature, menuOpen: false));
  }

  void _onPermissionsChanged(
      NavigationPermissionsChanged event,
      Emitter<NavigationState> emit,
      ) {
    final newPermissions      = event.permissions;
    final currentStillAllowed = newPermissions.allows(state.currentFeature);

    AppFeature nextFeature = state.currentFeature;

    if (!_ownerRedirectDone && newPermissions.isOwner) {
      // Owners land on Business screen on first login.
      nextFeature       = AppFeature.business;
      _ownerRedirectDone = true;
    } else if (!currentStillAllowed) {
      // Current screen not allowed for this role → fall back to POS.
      nextFeature = AppFeature.pos;
    }

    emit(state.copyWith(
      permissions:    newPermissions,
      currentFeature: nextFeature,
    ));
  }

  void _onReset(
      NavigationReset event,
      Emitter<NavigationState> emit,
      ) {
    _ownerRedirectDone = false;
    emit(NavigationState.initial());
  }

  void _onSetMenuOpen(
      SetMenuOpenEvent event,
      Emitter<NavigationState> emit,
      ) {
    emit(state.copyWith(menuOpen: event.open ?? !state.menuOpen));
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
