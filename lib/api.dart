import 'package:http/http.dart' as http;

const String _API = 'https://us-central1-islay-foundation.cloudfunctions.net/';
const String _apiAutoComplete = _API + 'getAutoComplete';

Future<http.Response> getAutoComplete(String query) {
  return http.get('$_apiAutoComplete?q=$query');
}
