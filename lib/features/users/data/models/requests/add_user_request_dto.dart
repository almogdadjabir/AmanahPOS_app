class AddUserRequestDto {
  String? fullName;
  String? address;
  String? phone;
  String? role;

  AddUserRequestDto({this.fullName, this.address, this.phone, this.role});

  AddUserRequestDto.fromJson(Map<String, dynamic> json) {
    fullName = json['full_name'];
    address = json['address'];
    phone = json['phone'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
    };
  }
}