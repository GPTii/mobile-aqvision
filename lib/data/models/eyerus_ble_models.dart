class EyerusBleInfo {
  final int proto;
  final String name;
  final String deviceId;
  final String model;
  final String fw;
  final String btMac;
  final String hostname;
  final int webPort;
  final bool setupMode;
  final List<String> caps;

  EyerusBleInfo.fromJson(Map<String, dynamic> json)
      : proto = json['proto'] ?? 0,
        name = json['name'] ?? '',
        deviceId = json['device_id'] ?? '',
        model = json['model'] ?? '',
        fw = json['fw'] ?? '',
        btMac = json['bt_mac'] ?? '',
        hostname = json['hostname'] ?? '',
        webPort = json['web_port'] ?? 5050,
        setupMode = json['setup_mode'] ?? false,
        caps = List<String>.from(json['caps'] ?? []);
}

class EyerusBleStatus {
  final bool setupMode;
  final bool online;
  final String busy;
  final Map<String, dynamic> wifi;
  final Map<String, dynamic> ethernet;
  
  EyerusBleStatus.fromJson(Map<String, dynamic> json)
      : setupMode = json['setup_mode'] ?? false,
        online = json['online'] ?? false,
        busy = json['busy'] ?? '',
        wifi = json['wifi'] ?? {},
        ethernet = json['ethernet'] ?? {};
}

class EyerusBleNetwork {
  final String ssid;
  final int signal;
  final bool secure;
  final bool inUse;
  final bool saved;

  EyerusBleNetwork.fromJson(Map<String, dynamic> json)
      : ssid = json['ssid'] ?? '',
        signal = json['signal'] ?? 0,
        secure = json['secure'] ?? false,
        inUse = json['in_use'] ?? false,
        saved = json['saved'] ?? false;
}

class EyerusBleResult {
  final String cmd;
  final String id;
  final int seq;
  final bool ok;
  final String error;
  final String message;
  final String? ip;
  final Map<String, dynamic> raw;

  EyerusBleResult.fromJson(Map<String, dynamic> json)
      : cmd = json['cmd'] ?? '',
        id = (json['id'] ?? '').toString(),
        seq = json['seq'] ?? 0,
        ok = json['ok'] == true,
        error = json['error'] ?? '',
        message = json['message'] ?? '',
        ip = json['ip'],
        raw = json;
}