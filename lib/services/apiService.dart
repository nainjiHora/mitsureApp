import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mittsure/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL of your API
  // static const String baseUrl = 'https://mittsureone.com:3001';
  static const String baseUrl = 'https://mittsure.qdegrees.com:3001';
  //
  // Function to get the token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('Token');  // Assuming token is stored under the key 'token'
  }

  // Common API call function
  static Future<dynamic> _callApi({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final String? token = await _getToken();

    // Set default headers
    Map<String, String> defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add Authorization token to headers if available
    if (token != null) {
      defaultHeaders['Token'] = 'token=$token';
      defaultHeaders['token'] = 'token=$token';
    }

    // Final headers
    headers = {...defaultHeaders, ...?headers};

    final Uri url = Uri.parse('$baseUrl$endpoint');

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: json.encode(body));

          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: json.encode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers, body: json.encode(body));
          break;
        default:
          throw Exception('Invalid HTTP method');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if(jsonDecode(response.body)['message']=="Session Expired Please LogIn Again"){


         return {"code":500};
          }else {
          return json.decode(response.body);
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error making API call: $e');
    }
  }

  // GET request method
  static Future<dynamic> get({
    required String endpoint,
    Map<String, String>? headers,
  }) async {
    return await _callApi(method: 'GET', endpoint: endpoint, headers: headers);
  }

  // POST request method
  static Future<dynamic> post({
    required String endpoint,
    required dynamic body,
    Map<String, String>? headers,
  }) async {
    return await _callApi(method: 'POST', endpoint: endpoint, headers: headers, body: body);
  }

  // PUT request method
  static Future<dynamic> put({
    required String endpoint,
    required dynamic body,
    Map<String, String>? headers,
  }) async {
    return await _callApi(method: 'PUT', endpoint: endpoint, headers: headers, body: body);
  }

  // DELETE request method
  static Future<dynamic> delete({
    required String endpoint,
    required dynamic body,
    Map<String, String>? headers,
  }) async {
    return await _callApi(method: 'DELETE', endpoint: endpoint, headers: headers, body: body);
  }


}
