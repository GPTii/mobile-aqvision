void main() {
  String serverUrl = 'https://dev1.aqvision.net';
  String app = 'live';
  String stream = 'cam_sanh_le_tan';
  String date = '2026-08-24';
  String fileName = '2026-08-24-00-19-00-0.mp4';
  String token = 'my_token';

  var base = Uri.parse(serverUrl);
  if (base.scheme == 'https' && base.host.startsWith('dev1')) {
    base = base.replace(scheme: 'http');
  }
  
  Uri mp4Uri = base.replace(
    pathSegments: [
      ...base.pathSegments.where((s) => s.isNotEmpty),
      'api',
      'media',
      'record',
      app,
      stream,
      date,
      fileName,
    ],
    queryParameters: {
      'access_token': token,
    },
  );
  
  print(mp4Uri.toString());
}
