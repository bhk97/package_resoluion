class CompatibilityMatrix {
  static const Map<String, String> agpToMinGradle = {
    '9.0': '8.11.1',
    '8.9': '8.11.1',
    '8.8': '8.10.2',
    '8.7': '8.9',
    '8.6': '8.7',
    '8.5': '8.7',
    '8.4': '8.6',
    '8.3': '8.4',
    '8.2': '8.2',
    '8.1': '8.0',
    '8.0': '8.0',
    '7.4': '7.5',
    '7.3': '7.4',
    '7.2': '7.3.3',
    '7.1': '7.2',
    '7.0': '7.0',
  };

  static const Map<String, int> agpToMinJdk = {
    '9.0': 17,
    '8.9': 17,
    '8.8': 17,
    '8.7': 17,
    '8.6': 17,
    '8.5': 17,
    '8.4': 17,
    '8.3': 17,
    '8.2': 17,
    '8.1': 17,
    '8.0': 17,
    '7.4': 11,
    '7.3': 11,
    '7.2': 11,
    '7.1': 11,
    '7.0': 11,
  };

  static const Map<int, String> compileSdkToMinAgp = {
    36: '8.9',
    35: '8.3',
    34: '8.1',
    33: '7.4',
    32: '7.2',
    31: '7.0',
  };

  static const List<SafeCombo> safeCombos = [
    SafeCombo(
      flutter: '3.27',
      agp: '8.9.0',
      gradle: '8.11.1',
      kotlin: '1.9.22',
      compileSdk: 35,
      minSdk: 21,
      jdk: 17,
      iosTarget: '13.0',
    ),
    SafeCombo(
      flutter: '3.22',
      agp: '8.3.2',
      gradle: '8.4',
      kotlin: '1.9.22',
      compileSdk: 34,
      minSdk: 21,
      jdk: 17,
      iosTarget: '12.0',
    ),
    SafeCombo(
      flutter: '3.19',
      agp: '8.2.2',
      gradle: '8.2',
      kotlin: '1.9.22',
      compileSdk: 34,
      minSdk: 21,
      jdk: 17,
      iosTarget: '12.0',
    ),
    SafeCombo(
      flutter: '3.16',
      agp: '8.1.0',
      gradle: '8.0',
      kotlin: '1.8.22',
      compileSdk: 34,
      minSdk: 21,
      jdk: 17,
      iosTarget: '12.0',
    ),
    SafeCombo(
      flutter: '3.13',
      agp: '7.4.2',
      gradle: '7.6.3',
      kotlin: '1.8.22',
      compileSdk: 33,
      minSdk: 21,
      jdk: 11,
      iosTarget: '12.0',
    ),
  ];

  static String? minGradleForAgp(String agpVersion) {
    final major = _majorMinor(agpVersion);
    return agpToMinGradle[major];
  }

  static int? minJdkForAgp(String agpVersion) {
    final major = _majorMinor(agpVersion);
    return agpToMinJdk[major];
  }

  static String? minAgpForCompileSdk(int compileSdk) {
    return compileSdkToMinAgp[compileSdk];
  }

  static String _majorMinor(String version) {
    final parts = version.split('.');
    if (parts.length >= 2) return '${parts[0]}.${parts[1]}';
    return version;
  }
}

class SafeCombo {
  const SafeCombo({
    required this.flutter,
    required this.agp,
    required this.gradle,
    required this.kotlin,
    required this.compileSdk,
    required this.minSdk,
    required this.jdk,
    required this.iosTarget,
  });

  final String flutter;
  final String agp;
  final String gradle;
  final String kotlin;
  final int compileSdk;
  final int minSdk;
  final int jdk;
  final String iosTarget;
}
