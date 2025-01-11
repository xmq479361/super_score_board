class AppSettings {
  bool isReversedDisplay;
  bool showTotalTime;
  String theme;
  bool isFaceToFace;

  AppSettings({
    this.isReversedDisplay = false,
    this.showTotalTime = true,
    this.theme = 'default',
    this.isFaceToFace = false,
  });

  Map<String, dynamic> toJson() => {
    'isReversedDisplay': isReversedDisplay,
    'showTotalTime': showTotalTime,
    'theme': theme,
    'isFaceToFace': isFaceToFace,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    isReversedDisplay: json['isReversedDisplay'] ?? false,
    showTotalTime: json['showTotalTime'] ?? true,
    theme: json['theme'] ?? 'default',
    isFaceToFace: json['isFaceToFace'] ?? false,
  );
}

