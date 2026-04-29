class AddCategoryRequestDto {
  String? name;
  String? description;

  AddCategoryRequestDto({this.name, this.description});

  AddCategoryRequestDto.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }
}