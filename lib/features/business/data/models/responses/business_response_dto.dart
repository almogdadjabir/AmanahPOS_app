class BusinessResponseDTO {
  bool? success;
  List<BusinessData>? data;

  BusinessResponseDTO({this.success, this.data});

  BusinessResponseDTO.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <BusinessData>[];
      json['data'].forEach((v) {
        data!.add(BusinessData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BusinessData {
  String? id;
  String? name;
  String? slug;
  String? businessType;
  Owner? owner;
  Null? logo;
  String? address;
  String? phone;
  String? email;
  ActiveSubscription? activeSubscription;
  bool? isActive;
  int? shopCount;
  List<Shops>? shops;
  String? createdAt;
  String? updatedAt;

  BusinessData(
      {this.id,
        this.name,
        this.slug,
        this.businessType,
        this.owner,
        this.logo,
        this.address,
        this.phone,
        this.email,
        this.activeSubscription,
        this.isActive,
        this.shopCount,
        this.shops,
        this.createdAt,
        this.updatedAt});

  BusinessData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    businessType = json['business_type'];
    owner = json['owner'] != null ? new Owner.fromJson(json['owner']) : null;
    logo = json['logo'];
    address = json['address'];
    phone = json['phone'];
    email = json['email'];
    activeSubscription = json['active_subscription'] != null
        ? new ActiveSubscription.fromJson(json['active_subscription'])
        : null;
    isActive = json['is_active'];
    shopCount = json['shop_count'];
    if (json['shops'] != null) {
      shops = <Shops>[];
      json['shops'].forEach((v) {
        shops!.add(new Shops.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['business_type'] = businessType;
    if (owner != null) {
      data['owner'] = owner!.toJson();
    }
    data['logo'] = logo;
    data['address'] = address;
    data['phone'] = phone;
    data['email'] = email;
    if (activeSubscription != null) {
      data['active_subscription'] = activeSubscription!.toJson();
    }
    data['is_active'] = isActive;
    data['shop_count'] = shopCount;
    if (shops != null) {
      data['shops'] = shops!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Owner {
  String? id;
  String? phone;
  String? email;
  String? fullName;
  String? role;
  bool? isVerified;
  bool? hasPassword;
  String? createdAt;
  String? lastLoginAt;

  Owner(
      {this.id,
        this.phone,
        this.email,
        this.fullName,
        this.role,
        this.isVerified,
        this.hasPassword,
        this.createdAt,
        this.lastLoginAt});

  Owner.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    phone = json['phone'];
    email = json['email'];
    fullName = json['full_name'];
    role = json['role'];
    isVerified = json['is_verified'];
    hasPassword = json['has_password'];
    createdAt = json['created_at'];
    lastLoginAt = json['last_login_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['phone'] = phone;
    data['email'] = email;
    data['full_name'] = fullName;
    data['role'] = role;
    data['is_verified'] = isVerified;
    data['has_password'] = hasPassword;
    data['created_at'] = createdAt;
    data['last_login_at'] = lastLoginAt;
    return data;
  }
}

class Shops {
  String? id;
  String? business;
  String? name;
  String? address;
  String? phone;
  bool? isActive;
  String? createdAt;
  String? updatedAt;

  Shops(
      {this.id,
        this.business,
        this.name,
        this.address,
        this.phone,
        this.isActive,
        this.createdAt,
        this.updatedAt});

  Shops.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    business = json['business'];
    name = json['name'];
    address = json['address'];
    phone = json['phone'];
    isActive = json['is_active'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['business'] = business;
    data['name'] = name;
    data['address'] = address;
    data['phone'] = phone;
    data['is_active'] = isActive;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class ActiveSubscription {
  String? id;
  String? name;
  int? maxShops;
  int? maxProducts;
  int? maxUsers;
  Features? features;
  bool? isFree;
  String? price;
  String? currency;
  String? endDate;
  int? daysRemaining;

  ActiveSubscription(
      {this.id,
        this.name,
        this.maxShops,
        this.maxProducts,
        this.maxUsers,
        this.features,
        this.isFree,
        this.price,
        this.currency,
        this.endDate,
        this.daysRemaining});

  ActiveSubscription.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    maxShops = json['max_shops'];
    maxProducts = json['max_products'];
    maxUsers = json['max_users'];
    features = json['features'] != null
        ? new Features.fromJson(json['features'])
        : null;
    isFree = json['is_free'];
    price = json['price'];
    currency = json['currency'];
    endDate = json['end_date'];
    daysRemaining = json['days_remaining'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['max_shops'] = maxShops;
    data['max_products'] = maxProducts;
    data['max_users'] = maxUsers;
    if (features != null) {
      data['features'] = features!.toJson();
    }
    data['is_free'] = isFree;
    data['price'] = price;
    data['currency'] = currency;
    data['end_date'] = endDate;
    data['days_remaining'] = daysRemaining;
    return data;
  }
}

class Features {
  bool? pos;
  bool? reports;
  bool? customers;
  bool? inventory;
  bool? apiAccess;
  bool? staffManagement;

  Features(
      {this.pos,
        this.reports,
        this.customers,
        this.inventory,
        this.apiAccess,
        this.staffManagement});

  Features.fromJson(Map<String, dynamic> json) {
    pos = json['pos'];
    reports = json['reports'];
    customers = json['customers'];
    inventory = json['inventory'];
    apiAccess = json['api_access'];
    staffManagement = json['staff_management'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pos'] = pos;
    data['reports'] = reports;
    data['customers'] = customers;
    data['inventory'] = inventory;
    data['api_access'] = apiAccess;
    data['staff_management'] = staffManagement;
    return data;
  }
}
