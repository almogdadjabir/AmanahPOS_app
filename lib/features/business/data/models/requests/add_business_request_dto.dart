class AddBusinessRequestDto {
  String? name;
  String? address;
  String? phone;
  String? email;

  AddBusinessRequestDto({this.name, this.address, this.phone, this.email});

  AddBusinessRequestDto.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    address = json['address'];
    phone = json['phone'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    };
  }
}