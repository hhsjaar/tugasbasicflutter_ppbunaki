class ApiKeyResponse {
  final bool success;
  final String? apiKey; // Ubah dari 'data' menjadi 'apiKey' untuk lebih eksplisit
  final String? message;

  ApiKeyResponse({
    required this.success,
    this.apiKey,
    this.message,
  });

  factory ApiKeyResponse.fromJson(Map<String, dynamic> json) {
    return ApiKeyResponse(
      success: json['success'] ?? false,
      apiKey: json['data'], 
      message: json['message'],
    );
  }
}