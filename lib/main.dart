import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterAppAuth appAuth = const FlutterAppAuth();
  final String _clientId = '5d9c02ca-d3a8-4981-930a-74ae56d428e3';
  final String _redirectUrl =
      'https://MSDFGOVQAB2CStg.b2clogin.com/oauth2/nativeclient/';
  final String _discoveryURL =
      'https://msdfgovqab2cstg.b2clogin.com/MSDFGOVQAB2CStg.onmicrosoft.com/B2C_1_sokoon/v2.0/.well-known/openid-configuration/';
  final String _authorizeUrl =
      'https://msdfgovqab2cstg.b2clogin.com/MSDFGOVQAB2CStg.onmicrosoft.com/oauth2/v2.0/authorize?p=B2C_1_sokoon';
  final String _tokenUrl =
      'https://msdfgovqab2cstg.b2clogin.com/msdfgovqab2cstg.onmicrosoft.com/oauth2/v2.0/token?p=B2C_1_sokoon';
  late String _idToken;
  late String _refreshToken;
  late String _accessToken;
  late String _accessTokenExpiration;
  late String _displayName = "";
  String _email = "";
  late Map<String, dynamic>? _jwt = null;
  final List<String> _scopes = ['openid'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: (_jwt == null)
              ? <Widget>[
                  const Text(
                    'Please press + sign to log in',
                  )
                ]
              : <Widget>[
                  Text(
                    'Display Name: $_displayName',
                  ),
                  const Text(' '),
                  Text(
                    'Email: $_email',
                  ),
                  const Text(' '),
                  ElevatedButton(
                    onPressed: _logOut,
                    child: const Text('Logout'),
                  )
                ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logIn,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _logIn() async {
    try {
      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            tokenEndpoint: _tokenUrl,
            authorizationEndpoint: _authorizeUrl,
          ),
          scopes: _scopes,
        ),
      );
      if (result != null) {
        _processAuthTokenResponse(result);
      }
    } catch (e) {
      print(e);
    }
  }

  void _processAuthTokenResponse(AuthorizationTokenResponse response) {
    setState(() {
      _idToken = response.idToken ?? '';
      _accessToken = response.accessToken ?? '';
      _refreshToken = response.refreshToken ?? '';
      _accessTokenExpiration =
          response.accessTokenExpirationDateTime?.toIso8601String() ?? '';
      // Parse the JWT regardless of _idToken being null or not
      _jwt = parseJwt(response.idToken!);
      _displayName = _jwt?['name']?.toString() ?? '';
      _email = _jwt?['emails']?[0]?.toString() ?? '';
    });
  }

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }
    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }
    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }

  Future<void> _logOut() async {
    try {
      Map<String, String> additionalParameters = {}; // Initialize here
      if (Platform.isAndroid) {
        additionalParameters = {
          "id_token_hint": _idToken,
          "post_logout_redirect_uri": _redirectUrl
        };
      } else if (Platform.isIOS) {
        additionalParameters = {
          "id_token_hint": _idToken,
          "post_logout_redirect_uri": _redirectUrl,
          'p': 'B2C_1_susi'
        };
      }
      await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          promptValues: ['login'],
          discoveryUrl: _discoveryURL,
          additionalParameters: additionalParameters,
          scopes: _scopes,
        ),
      );
    } catch (e) {
      print(e);
    }
    setState(() {
      _jwt = null;
    });
  }
}
