void main() {
  var base = Uri.parse('https://dev1.aqvision.net');
  base = base.replace(scheme: 'http');
  print(base.toString());
}
