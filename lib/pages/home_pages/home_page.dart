import 'package:event_follow/main.dart';
import 'package:event_follow/pages/events_pages/events_page.dart';
import 'package:event_follow/pages/home_pages/home_footer.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:twitter_login/twitter_login.dart';
import 'dart:convert';

bool isLoading = false;

class HomePage extends HookWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.0),
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 6/7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    flex: 1,
                    child: Container()
                ),
                Container(child: Image.asset("assets/logo_transparent.png", height: 80,)),
                Expanded(
                    flex: 2,
                    child: Container()
                ),
                !isLoading ? Container(
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: Image.asset("assets/twitter_logo.png", height: 25,),
                    label: Text("Twitterでログイン"),
                    onPressed: () async {
                      final twitterLogin = TwitterLogin(
                          apiKey: env["TWITTER_API_KEY"],
                          apiSecretKey: env["TWITTER_API_SECRET_KEY"],
                          redirectURI: env["TWITTER_REDIRECT_RUI"]
                      );
                      final authResult = await twitterLogin.login();
                      switch (authResult.status) {
                        case TwitterLoginStatus.loggedIn:
                        // setState(() {
                        //   isLoading = true;
                        // });
                          final credential = TwitterAuthProvider.credential(
                              accessToken: authResult.authToken,
                              secret: authResult.authTokenSecret);
                          final firebaseCredential = await firebaseAuth.signInWithCredential(credential);

                          final idToken = await firebaseCredential.user?.getIdToken();

                          final request = SessionApiRequest(
                              token: idToken!,
                              accessToken: authResult.authToken,
                              accessTokenSecret: authResult.authTokenSecret);

                          final sessionApiResults =
                          await requestSessionApi(request: request);
                          if (sessionApiResults.status == "OK") {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) {
                                  return EventsPage();
                                }));
                          }

                          break;
                        case TwitterLoginStatus.cancelledByUser:
                        // setState(() {
                        //   isLoading = false;
                        // });
                          break;
                        case TwitterLoginStatus.error:
                        // setState(() {
                        //   isLoading = false;
                        // });
                          break;
                      }

                    },
                  ),
                ) : Container(
                    height: 44,
                    width: 44,
                    child: CircularProgressIndicator()
                ),
                Expanded(
                    flex: 3,
                    child: Container()
                ),
                HomeFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


Future<SessionApiResults> requestSessionApi(
    {required SessionApiRequest request}) async {
  final url =
  Uri.parse("https://event-follow-front.herokuapp.com/api/sessions");
  final response = await http.post(
    url,
    body: json.encode(request.toJson()),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    return SessionApiResults.fromJson(json.decode(response.body));
  } else {
    throw Exception("Login Failed");
  }
}

class SessionApiRequest {
  final String token;
  final String accessToken;
  final String accessTokenSecret;

  SessionApiRequest({
    required this.token,
    required this.accessToken,
    required this.accessTokenSecret,
  });

  Map<String, dynamic> toJson() => {
    "token": this.token,
    "access_token": this.accessToken,
    "access_token_secret": this.accessTokenSecret,
  };
}

class SessionApiResults {
  final String status;
  final String? message;

  SessionApiResults({
    required this.status,
    this.message,
  });

  factory SessionApiResults.fromJson(Map<String, dynamic> json) {
    return SessionApiResults(status: json["status"], message: json["message"]);
  }
}
