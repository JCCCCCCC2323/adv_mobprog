import 'package:flutter_dotenv/flutter_dotenv.dart';

const defaultHost = 'https://dummyjson.com';
var host = dotenv.env['HOST']?.isNotEmpty == true
    ? dotenv.env['HOST']
    : defaultHost;
