import 'package:amana_pos/features/business/data/models/requests/add_business_request_dto.dart';
import 'package:amana_pos/features/business/data/models/requests/add_shop_request_dto.dart';
import 'package:amana_pos/features/business/data/models/requests/edit_business_request_dto.dart';
import 'package:amana_pos/features/business/data/models/requests/edit_shop_request_dto.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'business_event.dart';
part 'business_state.dart';


class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessUseCase useCase;
  final OfflineLocalCache offlineLocalCache;

  BusinessBloc({
    required this.useCase,
    required this.offlineLocalCache,
  }) : super(BusinessState.initial()) {
    on<OnBusinessInitial>(_init);
    on<OnEditBusiness>(_editBusiness);
    on<OnAddBusiness>(_addBusiness);
    on<OnDeactivateBusiness>(_deactivateBusiness);
    on<OnAddShop>(_addShop);
    on<OnEditShop>(_editShop);
  }

  Future<void> _init(
      OnBusinessInitial event,
      Emitter<BusinessState> emit,
      ) async {
    await _loadBusiness(emit);
  }


  Future<void> _loadBusiness(Emitter<BusinessState> emit) async {
    if (state.businessStatus == BusinessStatus.loading) return;

    var emittedCache = false;

    try {
      final cachedBusinesses = await offlineLocalCache.getBusinesses();

      if (emit.isDone) return;

      if (cachedBusinesses.isNotEmpty) {
        emittedCache = true;

        emit(
          state.copyWith(
            isLoading: false,
            businessStatus: BusinessStatus.success,
            businessList: cachedBusinesses,
            clearResponseError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: true,
            businessStatus: BusinessStatus.loading,
            clearResponseError: true,
          ),
        );
      }

      final response = await useCase.getBusinessList();

      if (emit.isDone) return;

      final error = response.getLeft().toNullable();
      final business = response.getRight().toNullable();

      if (error != null) {
        if (emittedCache) {
          emit(
            state.copyWith(
              isLoading: false,
              businessStatus: BusinessStatus.success,
              responseError: error,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            isLoading: false,
            responseError: error,
            businessStatus: BusinessStatus.failure,
          ),
        );
        return;
      }

      final freshBusinesses = business?.data ?? [];

      await offlineLocalCache.saveBusinessesToCache(freshBusinesses);

      if (emit.isDone) return;

      final normalizedBusinesses = await offlineLocalCache.getBusinesses();

      if (emit.isDone) return;

      emit(
        state.copyWith(
          isLoading: false,
          businessList: normalizedBusinesses,
          businessStatus: BusinessStatus.success,
          clearResponseError: true,
        ),
      );
    } catch (e) {
      if (emit.isDone) return;

      if (emittedCache) {
        emit(
          state.copyWith(
            isLoading: false,
            businessStatus: BusinessStatus.success,
            responseError: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          responseError: e.toString(),
          businessStatus: BusinessStatus.failure,
        ),
      );
    }
  }

  Future<void> _addBusiness(
      OnAddBusiness event,
      Emitter<BusinessState> emit,
      ) async {
    if(state.submitStatus == BusinessSubmitStatus.loading){
      return;
      }

    emit(state.copyWith(
      submitStatus: BusinessSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final payload = AddBusinessRequestDto(
        name: event.name,
        address: event.address,
        phone: event.phone,
        email: event.email,
      );
      final response = await useCase.addBusiness(payload);

      response.fold(
            (error) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.failure,
          submitError: error,
        )),
            (newBusiness) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.success,
              businessList: [
                ...?state.businessList,
                newBusiness.data!,
              ],
            )),
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: BusinessSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  Future<void> _deactivateBusiness(
      OnDeactivateBusiness event,
      Emitter<BusinessState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: BusinessSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.deactivateBusiness(event.businessId);

      response.fold(
            (error) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.failure,
          submitError: error,
        )),
            (_) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.success,
          businessList: state.businessList?.map((b) {
            return b.id == event.businessId
                ? BusinessData(
              id: b.id, name: b.name, slug: b.slug,
              owner: b.owner, logo: b.logo, address: b.address,
              phone: b.phone, email: b.email,
              isActive: false,
              shopCount: b.shopCount, shops: b.shops,
              createdAt: b.createdAt, updatedAt: b.updatedAt,
            )
                : b;
          }).toList(),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: BusinessSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  Future<void> _editBusiness(
      OnEditBusiness event,
      Emitter<BusinessState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: BusinessSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.editBusiness(
        event.businessId,
        EditBusinessRequestDto(
          name: event.name,
          address: event.address,
          phone: event.phone,
          email: event.email,
        ),
      );

      response.fold(
            (error) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.failure,
          submitError: error,
        )),
            (_) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.success,
          businessList: state.businessList?.map((b) {
            return b.id == event.businessId
                ? BusinessData(
              id: b.id,
              name: event.name,
              address: event.address,
              phone: event.phone,
              email: event.email,
              slug: b.slug,
              owner: b.owner,
              logo: b.logo,
              isActive: b.isActive,
              shopCount: b.shopCount,
              shops: b.shops,
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            )
                : b;
          }).toList(),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: BusinessSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  Future<void> _addShop(
      OnAddShop event,
      Emitter<BusinessState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: BusinessSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.addShop(
        event.businessId,
        AddShopRequestDto(
          name: event.name,
          address: event.address,
          phone: event.phone,
        ),
      );

      response.fold(
            (error) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.failure,
          submitError: error,
        )),
            (newShop) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.success,
          businessList: state.businessList?.map((b) {
            if (b.id != event.businessId) return b;
            return BusinessData(
              id: b.id,
              name: b.name,
              slug: b.slug,
              owner: b.owner,
              logo: b.logo,
              address: b.address,
              phone: b.phone,
              email: b.email,
              isActive: b.isActive,
              shopCount: (b.shopCount ?? 0) + 1,
              shops: [...?b.shops, newShop.data!],
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            );
          }).toList(),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: BusinessSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }


  Future<void> _editShop(
      OnEditShop event,
      Emitter<BusinessState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: BusinessSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.editShop(
        event.businessId,
        event.shopId,
        EditShopRequestDto(
          name: event.name,
          address: event.address,
          phone: event.phone,
        ),
      );

      response.fold(
            (error) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.failure,
          submitError: error,
        )),
            (_) => emit(state.copyWith(
          submitStatus: BusinessSubmitStatus.success,
          businessList: state.businessList?.map((b) {
            if (b.id != event.businessId) return b;
            return BusinessData(
              id: b.id, name: b.name, slug: b.slug, owner: b.owner,
              logo: b.logo, address: b.address, phone: b.phone,
              email: b.email, isActive: b.isActive,
              shopCount: b.shopCount, createdAt: b.createdAt,
              updatedAt: b.updatedAt,
              shops: b.shops?.map((s) {
                if (s.id != event.shopId) return s;
                return Shops(
                  id: s.id,
                  business:  s.business,
                  name: event.name,
                  address: event.address,
                  phone: event.phone,
                  isActive:  s.isActive,
                  createdAt: s.createdAt,
                  updatedAt: s.updatedAt,
                );
              }).toList(),
            );
          }).toList(),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: BusinessSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }


}